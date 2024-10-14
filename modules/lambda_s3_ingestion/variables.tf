variable "s3_lambda_layers_bucket" {
  description = "S3 bucket for Lambda layers"
  type        = string
}

variable "s3_lambda_destination_bucket" {
  description = "S3 bucket for Lambda destination"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_file_path" {
  description = "path of the Lambda function to import"
  type        = string
}

variable "lambda_layer_file_path" {
  description = "Local path of the Lambda Layer to import"
  type        = string  
}
