## Glue Role to access S3
## Create Glue IAM Role
resource "aws_iam_role" "glue_role" {
  name = "glue-service-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create custom policy to access S3
resource "aws_iam_policy" "glue_s3_access_policy" {
  name = "glue_s3_access_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*" # Access to all objects in the bucket
      }
    ]
  })
}

# Attach the AWS managed policy for Glue service roles
resource "aws_iam_role_policy_attachment" "glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_access_policy.arn
}

# JSON Classifier
resource "aws_glue_classifier" "json_classifier" {
  name = var.classifier_name
  json_classifier {
    json_path = var.json_path
  }
}

# Create Database name
resource "aws_glue_catalog_database" "my_database" {
  name = "etl-pipeline-iac-my-catalog-db"
}

# Input Crawler
resource "aws_glue_crawler" "input-etl-crawler" {
  database_name = aws_glue_catalog_database.my_database.name
  name          = "input-crawler-etl"
  role          = aws_iam_role.glue_role.arn
  classifiers   = [aws_glue_classifier.json_classifier.name]
  
  s3_target {
    path = "s3://${var.s3_input_data}"
  }

  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${self.name}"
  }

}

# Glue Script Bucket
resource "aws_s3_bucket" "s3_bucket_glue_script" {
  bucket = var.glue_scripts_path
  force_destroy = true
}

# Glue Output Bucket
resource "aws_s3_bucket" "s3_bucket_glue_output" {
  bucket = var.glue_output_bucket
  force_destroy = true

}

# Null Resource to wait for the Glue Crawler to finish
resource "null_resource" "wait_for_crawler" {
  depends_on = [aws_glue_crawler.input-etl-crawler]

  provisioner "local-exec" {
    command = <<EOT
      # Wait for the Glue Crawler to finish
      CRAWLER_NAME=${aws_glue_crawler.input-etl-crawler.name}
      while true; do
        STATUS=$(aws glue get-crawler --name $CRAWLER_NAME --query 'Crawler.State' --output text)
        echo "Crawler state: $STATUS"
        if [[ "$STATUS" == "READY" || "$STATUS" == "STOPPING" || "$STATUS" == "STOPPED" ]]; then
          echo "Crawler has finished."
          break
        fi
        sleep 10
      done
    EOT
  }
}

# Put script object inside S3
resource "aws_s3_object" "glue_script_object" {
  bucket     = var.glue_scripts_path
  key        = var.glue_schema_processing_script_name
  source     = var.glue_script_source_path
  depends_on = [aws_s3_bucket.s3_bucket_glue_script]
}

resource "aws_glue_job" "glue_data_transformation_job" {
  name     = "schema_processing"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${var.glue_scripts_path}/${var.glue_schema_processing_script_name}"
    python_version  = "3"
  }

  default_arguments = {
    "--JOB_NAME"        = "schema_processing"
    "--DATABASE_NAME"   = aws_glue_catalog_database.my_database.name  # Set your database name
    "--TABLE_NAME"      = "etl_pipeline_iac_bucket_09072024"  # Set your table name
    "--DEST_BCKET_NAME"      = aws_s3_bucket.s3_bucket_glue_output.bucket  # Set your table name

  }
  
  number_of_workers = 2  # Required for Python Shell jobs
  worker_type = "G.1X"

  depends_on = [aws_s3_object.glue_script_object,
                null_resource.wait_for_crawler,  # Wait for the crawler to finish
                aws_glue_catalog_database.my_database,
                aws_s3_bucket.s3_bucket_glue_output]

  # Provisioner to run the job right after creation
   provisioner "local-exec" {
     command = "aws glue start-job-run --job-name ${self.name}"
   }
}


# Glue trigger
resource "aws_glue_trigger" "glue_trigger_etl" {
  name = var.glue_trigger_name
  type = "CONDITIONAL"

  actions {
    job_name = aws_glue_job.glue_data_transformation_job.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.input-etl-crawler.name
      crawl_state = "SUCCEEDED"

    }
  }
  start_on_creation = true

  depends_on = [ aws_glue_job.glue_data_transformation_job ]
}

# Null Resource to wait for the Glue Job to finish
resource "null_resource" "wait_for_glue_job" {
  provisioner "local-exec" {
    command = <<EOT
      JOB_NAME="schema_processing"
      while true; do
        # Get the job run state
        STATUS=$(aws glue get-job-runs --job-name $JOB_NAME --query 'JobRuns[0].JobRunState' --output text)

        echo "Current job state: $STATUS"

        # Check if the job has finished
        if [[ "$STATUS" == "SUCCEEDED" || "$STATUS" == "FAILED" || "$STATUS" == "STOPPED" ]]; then
          echo "Job has finished with state: $STATUS"
          break
        fi

        # Wait for 10 seconds before checking again
        sleep 10
      done
    EOT
  }

  depends_on = [aws_glue_job.glue_data_transformation_job]  # Ensure this runs after your Glue job
}

# Output Crawler to crawl the output table and add it to the Glue Catalog
resource "aws_glue_crawler" "output-etl-crawler" {
  database_name = aws_glue_catalog_database.my_database.name
  name          = "output-crawler-etl"
  role          = aws_iam_role.glue_role.arn
  
  s3_target {
    path = "s3://${aws_s3_bucket.s3_bucket_glue_output.bucket}"
  }

  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${self.name}"
  }
  depends_on = [null_resource.wait_for_glue_job]

}
