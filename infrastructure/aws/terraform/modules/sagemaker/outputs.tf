# infrastructure/aws/terraform/modules/sagemaker/outputs.tf

output "domain_id" {
  description = "ID of the SageMaker domain"
  value       = aws_sagemaker_domain.main.id
}

output "domain_url" {
  description = "URL of the SageMaker domain"
  value       = aws_sagemaker_domain.main.url
}

output "user_profile_arn" {
  description = "ARN of the SageMaker user profile"
  value       = aws_sagemaker_user_profile.main.arn
}

output "security_group_id" {
  description = "ID of the SageMaker security group"
  value       = aws_security_group.sagemaker.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.sagemaker.arn
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = {
    for repo in local.ecr_repositories :
    repo => aws_ecr_repository.sagemaker[repo].repository_url
  }
}

output "model_package_group_name" {
  description = "Name of the model package group"
  value       = aws_sagemaker_model_package_group.main.model_package_group_name
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker IAM role"
  value       = aws_iam_role.sagemaker.arn
}

output "jupyter_app_url" {
  description = "URL of the Jupyter application"
  value       = aws_sagemaker_app.jupyter.url
}