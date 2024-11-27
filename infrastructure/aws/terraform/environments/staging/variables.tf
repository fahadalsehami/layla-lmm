# infrastructure/aws/terraform/environments/staging/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_1a_cidr" {
  description = "CIDR block for public subnet 1a"
  type        = string
  default     = "10.1.1.0/24"
}

variable "public_subnet_1b_cidr" {
  description = "CIDR block for public subnet 1b"
  type        = string
  default     = "10.1.2.0/24"
}

variable "private_subnet_1a_cidr" {
  description = "CIDR block for private subnet 1a"
  type        = string
  default     = "10.1.10.0/24"
}

variable "private_subnet_1b_cidr" {
  description = "CIDR block for private subnet 1b"
  type        = string
  default     = "10.1.11.0/24"
}

variable "notebook_instance_type" {
  description = "SageMaker notebook instance type"
  type        = string
  default     = "ml.t3.xlarge"
}

variable "notebook_volume_size" {
  description = "SageMaker notebook volume size in GB"
  type        = number
  default     = 100
}

variable "lambda_source_path" {
  description = "Path to Lambda function source code"
  type        = string
}

variable "prod_account_id" {
  description = "AWS Account ID for production"
  type        = string
}