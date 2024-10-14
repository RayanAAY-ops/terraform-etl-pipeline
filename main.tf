provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "Project" = "TODELETE-etl-pipeline-iac"
    }
  }
}

module "lambda_s3_ingestion" {
  source                       = "./modules/lambda_s3_ingestion"
  s3_lambda_layers_bucket      = "lambda-layers-data-ingestion"
  s3_lambda_destination_bucket = "etl-pipeline-iac-bucket-09072024"
  lambda_function_name         = "python_ingestion_lambda"
  lambda_file_path             = "lambda-data/lambda_ingestion.zip"
  lambda_layer_file_path       = "${path.root}/lambda-layers/layer-data-ingestion.zip"
}



# Call the Glue module
module "glue_s3_transformation" {
  source                             = "./modules/glue_s3_transformation"
  region                             = var.region
  classifier_name                    = "my_json_classifier"
  json_path                          = "$[*]"
  s3_input_data                      = "etl-pipeline-iac-bucket-09072024"
  glue_scripts_path                  = "glue-scripts-data-10102024"
  glue_output_bucket                 = "glue-output-data-10102024"
  glue_schema_processing_script_name = "data_transformation.py"
  glue_script_source_path            = "/Users/raitaliyahia/Documents/aws-practice/etl-pipeline-iac/pipeline/data_transformation.py"
  glue_numbers_of_workers            = 2
  glue_worker_type                   = "G.1X"
  depends_on                         = [module.lambda_s3_ingestion]
}

module "eventbridge_lambda" {
  source               = "./modules/eventbridge_lambda_trigger"
  cron_expression      = "cron(* 0 * * ? *)" # Every day
  lambda_function_name = "python_compare_hash_lambda"
  lambda_file_path     = "lambda-data/data_compare_hash.zip"
  iam_role             = module.lambda_s3_ingestion.lambda_role.arn
  lambda_layer         = module.lambda_s3_ingestion.lambda_layer.arn
  depends_on           = [module.lambda_s3_ingestion]
}

module "athena" {
  source             = "./modules/athena"
  athena_bucket_name = "athena-script-output-09072024"
}