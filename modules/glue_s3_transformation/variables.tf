variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "classifier_name" {
  description = "Name of the Glue classifier"
  type        = string
}

variable "json_path" {
  description = "JSON path for the classifier"
  type        = string
}

variable "s3_input_data" {
  description = "S3 bucket for input data"
  type        = string
}

variable "glue_scripts_path" {
  description = "S3 bucket path for Glue scripts"
  type        = string
}

variable "glue_output_bucket" {
  description = "S3 bucket for Glue job output"
  type        = string
}

variable "glue_schema_processing_script_name" {
  description = "Name of the Glue schema processing script"
  type        = string
}

variable "glue_script_source_path" {
  description = "Local path of the Glue script to upload"
  type        = string
}

variable "glue_trigger_name" {
  description = "Local path of the Glue script to upload"
  type        = string 
  default = "glue_trigger"
}

variable "glue_numbers_of_workers" {
  description = "Glue number of workers"
  type        = number 
}

variable "glue_worker_type" {
   description = "Glue worker type"
  type        = string  
}