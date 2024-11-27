# infrastructure/aws/terraform/environments/prod/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "ID of the Production VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the Production VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets in Production VPC"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets in Production VPC"
  value       = module.vpc.public_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways in Production VPC"
  value       = module.vpc.nat_gateway_ids
}

output "vpc_flow_log_group" {
  description = "Name of the VPC Flow Log CloudWatch Log Group"
  value       = module.vpc.flow_log_group_name
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of Production ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of Production ECR repositories"
  value       = module.ecr.repository_arns
}

output "ecr_scan_rules" {
  description = "Names of ECR scan event rules"
  value       = module.ecr.scan_rules
}

# SageMaker Outputs
output "sagemaker_endpoint_name" {
  description = "Name of the Production SageMaker endpoint"
  value       = module.sagemaker.endpoint_name
}

output "sagemaker_endpoint_arn" {
  description = "ARN of the Production SageMaker endpoint"
  value       = module.sagemaker.endpoint_arn
}

output "sagemaker_notebook_url" {
  description = "URL of the Production SageMaker notebook instance"
  value       = module.sagemaker.notebook_instance_url
}

output "sagemaker_role_arn" {
  description = "ARN of the Production SageMaker IAM role"
  value       = module.sagemaker.sagemaker_role_arn
}

output "model_package_group_name" {
  description = "Name of the Production model package group"
  value       = module.sagemaker.model_package_group_name
}

# Lambda Outputs
output "lambda_function_names" {
  description = "Names of Production Lambda functions"
  value       = module.lambda.function_names
}

output "lambda_function_arns" {
  description = "ARNs of Production Lambda functions"
  value       = module.lambda.function_arns
}

output "lambda_function_urls" {
  description = "URLs of Production Lambda functions"
  value       = module.lambda.function_urls
}

output "lambda_role_arn" {
  description = "ARN of the Production Lambda IAM role"
  value       = module.lambda.lambda_role_arn
}

# IAM Outputs
output "iam_role_arns" {
  description = "ARNs of Production IAM roles"
  value = {
    sagemaker = module.iam.sagemaker_role_arn
    lambda    = module.iam.lambda_role_arn
    monitoring = module.iam.monitoring_role_arn
    data_processor = module.iam.data_processor_role_arn
  }
}

# KMS Outputs
output "kms_key_arns" {
  description = "ARNs of Production KMS keys"
  value = {
    sagemaker = module.sagemaker.kms_key_arn
    lambda    = module.lambda.kms_key_arn
    ecr       = module.ecr.kms_key_arn
  }
}

# Monitoring Outputs
output "cloudwatch_log_groups" {
  description = "Names of Production CloudWatch log groups"
  value       = module.lambda.log_group_names
}

output "monitoring_alarm_arns" {
  description = "ARNs of Production CloudWatch alarms"
  value = {
    lambda    = module.lambda.alarm_arns
    sagemaker = module.sagemaker.alarm_arns
    ecr       = module.ecr.alarm_arns
  }
}

output "monitoring_dashboard_urls" {
  description = "URLs of Production CloudWatch dashboards"
  value = {
    main      = module.monitoring.main_dashboard_url
    ml        = module.monitoring.ml_dashboard_url
    services  = module.monitoring.services_dashboard_url
  }
}

# Security Outputs
output "security_group_ids" {
  description = "IDs of Production security groups"
  value = {
    sagemaker = module.sagemaker.security_group_id
    lambda    = module.lambda.security_group_id
  }
}

output "waf_web_acl_arn" {
  description = "ARN of Production WAF web ACL"
  value       = var.enable_waf ? module.waf[0].web_acl_arn : null
}

# Backup Outputs
output "backup_vault_arn" {
  description = "ARN of Production backup vault"
  value       = module.backup.backup_vault_arn
}

output "backup_plan_arn" {
  description = "ARN of Production backup plan"
  value       = module.backup.backup_plan_arn
}

# High Availability Outputs
output "failover_status" {
  description = "Status of Production failover configuration"
  value = {
    multi_az_enabled = var.enable_multi_az
    dr_enabled       = var.disaster_recovery_enabled
    backup_retention = var.backup_retention_days
  }
}

# Compliance Outputs
output "compliance_status" {
  description = "Production compliance configuration status"
  value = {
    mode = var.compliance_mode
    vpc_flow_logs_enabled = true
    encryption_enabled    = true
    waf_enabled          = var.enable_waf
  }
}

# Tags Output
output "resource_tags" {
  description = "Common tags applied to Production resources"
  value = merge(
    {
      Environment = "production"
      Project     = "layla-app"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}