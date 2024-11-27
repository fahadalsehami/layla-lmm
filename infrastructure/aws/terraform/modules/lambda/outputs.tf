# infrastructure/aws/terraform/modules/lambda/outputs.tf

output "function_arns" {
  description = "ARNs of the Lambda functions"
  value = {
    for k, v in aws_lambda_function.functions : k => v.arn
  }
}

output "function_names" {
  description = "Names of the Lambda functions"
  value = {
    for k, v in aws_lambda_function.functions : k => v.function_name
  }
}

output "security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for Lambda encryption"
  value       = aws_kms_key.lambda.arn
}

output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value = {
    for k, v in aws_cloudwatch_log_group.lambda : k => v.name
  }
}

output "alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn
  }
}