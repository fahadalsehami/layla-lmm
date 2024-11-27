# infrastructure/aws/terraform/modules/s3/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["http://localhost:3000", "http://localhost:8501"]
}

variable "bucket_size_alarm_threshold" {
  description = "Threshold for bucket size alarm in bytes"
  type        = number
  default     = 5368709120  # 5GB in bytes
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
  default     = ""
}
