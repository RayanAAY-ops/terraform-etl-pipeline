resource "aws_iam_role" "lambda_role" {
  name = "lambda-service-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_access_policy" {
  name = "lambda_s3_access_policy"
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

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../pipeline/data_ingestion.py"
  output_path = "${path.root}/lambda-data/lambda_ingestion.zip"
}

resource "aws_iam_role_policy_attachment" "lambda_service_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_access_policy.arn
}

resource "aws_lambda_function" "lambda_ingestion" {
  filename      = var.lambda_file_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn

  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"
  handler          = "data_ingestion.lambda_handler"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  depends_on       = [aws_lambda_layer_version.lambda_layer]

  environment {
    variables = {
      BUCKET_NAME = var.s3_lambda_destination_bucket
    }
  }
}

resource "aws_s3_bucket" "s3_lambda_layers_bucket" {
  bucket        = var.s3_lambda_layers_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "s3_lambda_destination_bucket" {
  bucket        = var.s3_lambda_destination_bucket
  force_destroy = true
}

resource "aws_s3_object" "s3_lambda_layers_object" {
  bucket     = var.s3_lambda_layers_bucket
  key        = "lambda_ingestion"
  source     = var.lambda_layer_file_path
  depends_on = [aws_s3_bucket.s3_lambda_destination_bucket, aws_s3_bucket.s3_lambda_layers_bucket]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "env-data-ingestion"
  s3_bucket  = aws_s3_bucket.s3_lambda_layers_bucket.bucket
  s3_key     = aws_s3_object.s3_lambda_layers_object.key

  compatible_runtimes = ["python3.11"]
  depends_on          = [aws_s3_object.s3_lambda_layers_object]
}

data "aws_lambda_invocation" "lambda_invocation" {
  function_name = aws_lambda_function.lambda_ingestion.function_name

  input = <<JSON
{
  "key1": "value1"
}
JSON
  depends_on = [aws_lambda_function.lambda_ingestion, aws_lambda_layer_version.lambda_layer, aws_s3_bucket.s3_lambda_destination_bucket]
}
