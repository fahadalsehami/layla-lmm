# infrastructure/aws/terraform/environments/staging/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of ECR repositories"
  value       = module.ecr.repository_arns
}

output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  value       = module.sagemaker.endpoint_name
}

output "sagemaker_endpoint_arn" {
  description = "ARN of the SageMaker endpoint"
  value       = module.sagemaker.endpoint_arn
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker IAM role"
  value       = module.sagemaker.sagemaker_role_arn
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = module.lambda.function_names
}

output "lambda_function_arns" {
  description = "ARNs of Lambda functions"
  value       = module.lambda.function_arns
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.lambda.lambda_role_arn
}

output "cloudwatch_log_groups" {
  description = "Names of CloudWatch log groups"
  value       = module.lambda.log_group_names
}

output "kms_key_arns" {
  description = "ARNs of KMS keys"
  value = {
    sagemaker = module.sagemaker.kms_key_arn
    lambda    = module.lambda.kms_key_arn
    ecr       = module.ecr.kms_key_arn
  }
}

output "monitoring_alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value = {
    lambda    = module.lambda.alarm_arns
    sagemaker = module.sagemaker.alarm_arns
    ecr       = module.ecr.alarm_arns
  }
}