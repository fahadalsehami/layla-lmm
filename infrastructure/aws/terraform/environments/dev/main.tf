# infrastructure/aws/terraform/environments/dev/main.tf

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "development"
      Project     = "layla-app"
      ManagedBy   = "terraform"
    }
  }
}

# State Configuration
terraform {
  backend "s3" {
    bucket         = "layla-app-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "layla-app-terraform-locks-dev"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment         = "dev"
  vpc_cidr           = var.vpc_cidr
  public_subnet_1a_cidr  = var.public_subnet_1a_cidr
  public_subnet_1b_cidr  = var.public_subnet_1b_cidr
  private_subnet_1a_cidr = var.private_subnet_1a_cidr
  private_subnet_1b_cidr = var.private_subnet_1b_cidr
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  environment             = "dev"
  allowed_account_ids     = [data.aws_caller_identity.current.account_id]
  allowed_principal_arns  = [module.iam.sagemaker_role_arn, module.iam.lambda_role_arn]
  notification_topic_arn  = aws_sns_topic.notifications.arn
  alarm_topic_arn        = aws_sns_topic.alarms.arn
}

# SageMaker Module
module "sagemaker" {
  source = "../../modules/sagemaker"

  environment            = "dev"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  private_subnet_ids    = module.vpc.private_subnet_ids
  notebook_instance_type = "ml.t3.medium"
  data_bucket_arn       = module.s3.data_bucket_arn
  models_bucket_arn     = module.s3.models_bucket_arn
  s3_kms_key_arn       = module.s3.kms_key_arn
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"

  environment          = "dev"
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnet_ids
  data_bucket_arn     = module.s3.data_bucket_arn
  models_bucket_arn   = module.s3.models_bucket_arn
  s3_kms_key_arn     = module.s3.kms_key_arn
  sagemaker_endpoint_arn = module.sagemaker.endpoint_arn
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment           = "dev"
  data_bucket_arn      = module.s3.data_bucket_arn
  models_bucket_arn    = module.s3.models_bucket_arn
  logs_bucket_arn      = module.s3.logs_bucket_arn
  s3_kms_key_arn      = module.s3.kms_key_arn
  sagemaker_kms_key_arn = module.sagemaker.kms_key_arn
  sagemaker_endpoint_arn = module.sagemaker.endpoint_arn
}

# SNS Topics
resource "aws_sns_topic" "notifications" {
  name = "layla-app-notifications-dev"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic" "alarms" {
  name = "layla-app-alarms-dev"
  kms_master_key_id = "alias/aws/sns"
}

# Data Sources
data "aws_caller_identity" "current" {}