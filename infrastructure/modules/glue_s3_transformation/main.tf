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

# Crawler
resource "aws_glue_crawler" "etl_crawler" {
  database_name = aws_glue_catalog_database.my_database.name
  name          = "my-crawler-etl"
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
  depends_on = [aws_glue_crawler.etl_crawler]

  provisioner "local-exec" {
    command = <<EOT
      # Wait for the Glue Crawler to finish
      CRAWLER_NAME=${aws_glue_crawler.etl_crawler.name}
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
  depends_on = [aws_s3_object.glue_script_object,
                null_resource.wait_for_crawler,  # Wait for the crawler to finish
                aws_glue_catalog_database.my_database,
                aws_s3_bucket.s3_bucket_glue_output]

  # Provisioner to run the job right after creation
   provisioner "local-exec" {
     command = "aws glue start-job-run --job-name ${self.name}"
   }
}


