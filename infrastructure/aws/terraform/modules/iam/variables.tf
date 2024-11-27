# infrastructure/aws/terraform/modules/iam/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "data_bucket_arn" {
  description = "ARN of the S3 data bucket"
  type        = string
}

variable "models_bucket_arn" {
  description = "ARN of the S3 models bucket"
  type        = string
}

variable "logs_bucket_arn" {
  description = "ARN of the S3 logs bucket"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the S3 KMS key"
  type        = string
}

variable "sagemaker_kms_key_arn" {
  description = "ARN of the SageMaker KMS key"
  type        = string
}

variable "sagemaker_endpoint_arn" {
  description = "ARN of the SageMaker endpoint"
  type        = string
}

variable "enable_cross_account_access" {
  description = "Enable cross-account access"
  type        = bool
  default     = false
}

variable "trusted_account_ids" {
  description = "List of trusted AWS account IDs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}