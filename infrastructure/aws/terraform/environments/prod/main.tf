# infrastructure/aws/terraform/environments/prod/main.tf

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "layla-app"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment             = "prod"
  vpc_cidr               = var.vpc_cidr
  public_subnet_1a_cidr  = var.public_subnet_1a_cidr
  public_subnet_1b_cidr  = var.public_subnet_1b_cidr
  private_subnet_1a_cidr = var.private_subnet_1a_cidr
  private_subnet_1b_cidr = var.private_subnet_1b_cidr
  region                 = var.region
  enable_nat_gateway     = true
  enable_vpn_gateway     = true
  enable_flow_logs      = true
}

module "ecr" {
  source = "../../modules/ecr"

  environment                     = "prod"
  allowed_account_ids            = [data.aws_caller_identity.current.account_id]
  allowed_principal_arns         = [module.iam.sagemaker_role_arn]
  notification_topic_arn         = module.sns.notification_topic_arn
  alarm_topic_arn               = module.sns.alarm_topic_arn
  cross_account_replication     = false
}

module "sagemaker" {
  source = "../../modules/sagemaker"

  environment            = "prod"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  private_subnet_ids    = module.vpc.private_subnet_ids
  notebook_instance_type = var.notebook_instance_type
  notebook_volume_size  = var.notebook_volume_size
  data_bucket_arn      = module.s3.data_bucket_arn
  models_bucket_arn    = module.s3.models_bucket_arn
  s3_kms_key_arn      = module.s3.kms_key_arn
  enable_model_monitoring = true
  enable_auto_shutdown   = false
}

module "lambda" {
  source = "../../modules/lambda"

  environment            = "prod"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  private_subnet_ids    = module.vpc.private_subnet_ids
  data_bucket_arn      = module.s3.data_bucket_arn
  data_bucket_name     = module.s3.data_bucket_name
  models_bucket_arn    = module.s3.models_bucket_arn
  models_bucket_name   = module.s3.models_bucket_name
  s3_kms_key_arn      = module.s3.kms_key_arn
  lambda_source_path   = var.lambda_source_path
}

module "iam" {
  source = "../../modules/iam"

  environment            = "prod"
  data_bucket_arn       = module.s3.data_bucket_arn
  models_bucket_arn     = module.s3.models_bucket_arn
  logs_bucket_arn       = module.s3.logs_bucket_arn
  s3_kms_key_arn       = module.s3.kms_key_arn
  sagemaker_kms_key_arn = module.sagemaker.kms_key_arn
  sagemaker_endpoint_arn = module.sagemaker.endpoint_arn
  enable_cross_account_access = false
}

data "aws_caller_identity" "current" {}