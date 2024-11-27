# infrastructure/aws/terraform/modules/sagemaker/variables.tf

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

variable "models_bucket_arn" {
  description = "ARN of the S3 bucket for models"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  type        = string
}

variable "notebook_instance_type" {
  description = "Instance type for SageMaker notebook instances"
  type        = string
  default     = "ml.t3.medium"
}

variable "notebook_volume_size" {
  description = "Volume size in GB for notebook instances"
  type        = number
  default     = 50
  validation {
    condition     = var.notebook_volume_size >= 5 && var.notebook_volume_size <= 1024
    error_message = "Notebook volume size must be between 5 and 1024 GB"
  }
}

variable "enable_model_monitoring" {
  description = "Enable model monitoring features"
  type        = bool
  default     = true
}

variable "enable_auto_shutdown" {
  description = "Enable auto shutdown for notebook instances"
  type        = bool
  default     = true
}

variable "auto_shutdown_idle_time" {
  description = "Idle time in minutes before auto shutdown"
  type        = number
  default     = 60
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}