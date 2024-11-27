# infrastructure/aws/terraform/modules/ecr/outputs.tf

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.arn
  }
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.repository_url
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.name
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.ecr.arn
}

output "scan_rules" {
  description = "Names of the CloudWatch Event rules for scanning"
  value = {
    for k, v in aws_cloudwatch_event_rule.ecr_scan : k => v.name
  }
}

output "alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.image_scan_findings : k => v.arn
  }
}