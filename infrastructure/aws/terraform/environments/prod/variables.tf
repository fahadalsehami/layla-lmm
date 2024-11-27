# infrastructure/aws/terraform/environments/prod/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_1a_cidr" {
  description = "CIDR block for public subnet 1a"
  type        = string
  default     = "10.2.1.0/24"
}

variable "public_subnet_1b_cidr" {
  description = "CIDR block for public subnet 1b"
  type        = string
  default     = "10.2.2.0/24"
}

variable "private_subnet_1a_cidr" {
  description = "CIDR block for private subnet 1a"
  type        = string
  default     = "10.2.10.0/24"
}

variable "private_subnet_1b_cidr" {
  description = "CIDR block for private subnet 1b"
  type        = string
  default     = "10.2.11.0/24"
}

variable "notebook_instance_type" {
  description = "SageMaker notebook instance type"
  type        = string
  default     = "ml.t3.2xlarge"
  validation {
    condition     = can(regex("^ml\\.", var.notebook_instance_type))
    error_message = "Notebook instance type must be a valid SageMaker instance type starting with 'ml.'"
  }
}

variable "notebook_volume_size" {
  description = "SageMaker notebook volume size in GB"
  type        = number
  default     = 200
  validation {
    condition     = var.notebook_volume_size >= 100 && var.notebook_volume_size <= 500
    error_message = "Notebook volume size must be between 100 and 500 GB in production."
  }
}

variable "lambda_source_path" {
  description = "Path to Lambda function source code"
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 1024
  validation {
    condition     = var.lambda_memory_size >= 512 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 512 MB and 10240 MB."
  }
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.lambda_timeout >= 30 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring for all services"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
  validation {
    condition     = var.backup_retention_days >= 30 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 30 and 365 days in production."
  }
}

variable "alert_email" {
  description = "Email address for alerts and notifications"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP CIDR ranges for VPN access"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for ip in var.allowed_ip_ranges : can(cidrhost(ip, 0))])
    error_message = "All elements must be valid CIDR ranges."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_deletion_window" {
  description = "Deletion window for KMS keys in days"
  type        = number
  default     = 30
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "vpc_flow_log_retention" {
  description = "Number of days to retain VPC flow logs"
  type        = number
  default     = 90
  validation {
    condition     = var.vpc_flow_log_retention >= 90
    error_message = "VPC flow log retention must be at least 90 days in production."
  }
}

variable "enable_waf" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = true
}

variable "disaster_recovery_enabled" {
  description = "Enable disaster recovery configuration"
  type        = bool
  default     = true
}

variable "compliance_mode" {
  description = "Compliance mode for additional security controls"
  type        = string
  default     = "strict"
  validation {
    condition     = contains(["standard", "strict", "hipaa"], var.compliance_mode)
    error_message = "Compliance mode must be one of: standard, strict, hipaa."
  }
}