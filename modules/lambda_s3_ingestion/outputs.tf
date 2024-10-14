output "lambda_function_arn" {
  value = aws_lambda_function.lambda_ingestion.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "lambda_policy_arn" {
  value = aws_iam_policy.lambda_s3_access_policy.arn
}

output "lambda_role" {
  value = aws_iam_role.lambda_role
}

output "lambda_layer" {
  value = aws_lambda_layer_version.lambda_layer
  
}