variable "region" {
  default = "eu-west-3"
}

variable "classifier_name" {
  default = "etl-pipeline-iac-glue_classifier"
}

variable "json_path" {
  default = "$[*]"
}


variable "s3_input_data" {
  default = "etl-pipeline-iac-bucket-01072024"

}

variable "glue_scripts_path" {
  default = "politicians-glue-script"
}

variable "glue_schema_processing_script_name" {
  default = "schema_processing.py"
}

variable "glue_output_bucket" {
  default = "politicians-glue-output-bucket"
}