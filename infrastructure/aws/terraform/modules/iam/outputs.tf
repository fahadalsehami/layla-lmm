# infrastructure/aws/terraform/modules/iam/outputs.tf

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker role"
  value       = aws_iam_role.sagemaker.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda role"
  value       = aws_iam_role.lambda.arn
}

output "api_gateway_role_arn" {
  description = "ARN of the API Gateway role"
  value       = aws_iam_role.api_gateway.arn
}

output "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch role"
  value       = aws_iam_role.cloudwatch.arn
}

output "ml_pipeline_role_arn" {
  description = "ARN of the ML Pipeline role"
  value       = aws_iam_role.ml_pipeline.arn
}

output "data_processor_role_arn" {
  description = "ARN of the Data Processor role"
  value       = aws_iam_role.data_processor.arn
}

output "monitoring_role_arn" {
  description = "ARN of the Monitoring role"
  value       = aws_iam_role.monitoring.arn
}

output "cross_account_role_arn" {
  description = "ARN of the Cross-Account role"
  value       = var.enable_cross_account_access ? aws_iam_role.cross_account[0].arn : null
}