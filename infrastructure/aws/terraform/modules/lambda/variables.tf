# infrastructure/aws/terraform/modules/lambda/variables.tf

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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "data_bucket_arn" {
  description = "ARN of the S3 bucket for data"
  type        = string
}

variable "data_bucket_name" {
  description = "Name of the S3 bucket for data"
  type        = string
}

variable "models_bucket_arn" {
  description = "ARN of the S3 bucket for models"
  type        = string
}

variable "models_bucket_name" {
  description = "Name of the S3 bucket for models"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  type        = string
}

variable "sagemaker_endpoint_arn" {
  description = "ARN of the SageMaker endpoint"
  type        = string
}

variable "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  type        = string
}

variable "lambda_source_path" {
  description = "Path to the Lambda function source code"
  type        = string
}

variable "lambda_layer_arns" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "common_environment_variables" {
  description = "Common environment variables for all Lambda functions"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
