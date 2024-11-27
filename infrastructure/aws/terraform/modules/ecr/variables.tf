# infrastructure/aws/terraform/modules/ecr/variables.tf

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

variable "allowed_account_ids" {
  description = "List of AWS account IDs allowed to pull images"
  type        = list(string)
}

variable "allowed_principal_arns" {
  description = "List of IAM role/user ARNs allowed to push images"
  type        = list(string)
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for notifications"
  type        = string
}

variable "alarm_topic_arn" {
  description = "ARN of SNS topic for alarms"
  type        = string
}

variable "cross_account_replication" {
  description = "Enable cross-account replication"
  type        = bool
  default     = false
}

variable "replication_destination_registry" {
  description = "Registry ID for replication destination"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}