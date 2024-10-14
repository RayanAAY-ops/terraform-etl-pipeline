
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/data_compare_hash.py"
  output_path = "${path.root}/lambda/data_compare_hash.zip"
}

resource "aws_lambda_function" "data_compare_hash" {
  filename      = var.lambda_file_path
  function_name = var.lambda_function_name
  role          = var.iam_role
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"
  handler          = "data_compare_hash.lambda_handler"
  layers           = [var.lambda_layer]

}


data "aws_lambda_invocation" "lambda_invocation" {
  function_name = aws_lambda_function.data_compare_hash.function_name

  input = <<JSON
{
  "key1": "value1"
}
JSON
  depends_on = [aws_lambda_function.data_compare_hash]
}


resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "daily_lambda_event_rule"
  description = "Trigger target_lambda every day"
  schedule_expression = "cron(* * * * ? *)"  # This cron expression triggers the event every day at midnight UTC
}

resource "aws_lambda_permission" "allow_event_rule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_compare_hash.function_name  # Replace with your Lambda function's name
  principal     = "events.amazonaws.com"

  # Add the source ARN of the CloudWatch Event Rule
  source_arn = aws_cloudwatch_event_rule.event_rule.arn
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = "my_lambda_target"
  arn       = aws_lambda_function.data_compare_hash.arn  # Replace with your Lambda function ARN
}

