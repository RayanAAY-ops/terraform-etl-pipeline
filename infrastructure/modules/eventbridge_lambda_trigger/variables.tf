variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_file_path" {
  description = "path of the Lambda function to import"
  type        = string
}


variable "lambda_layer" {
  description = "Lambda layer to use"
  type        = string
}

variable "iam_role" {
  description = "IAM Role for Lambda"
  type        = string
}

variable "cron_expression" {
  description = "Cron expression scheduling"
  type = string
}