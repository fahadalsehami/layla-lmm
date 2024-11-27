# infrastructure/aws/terraform/environments/staging/main.tf

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = "layla-app"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment             = "staging"
  vpc_cidr               = var.vpc_cidr
  public_subnet_1a_cidr  = var.public_subnet_1a_cidr
  public_subnet_1b_cidr  = var.public_subnet_1b_cidr
  private_subnet_1a_cidr = var.private_subnet_1a_cidr
  private_subnet_1b_cidr = var.private_subnet_1b_cidr
  region                 = var.region
  enable_nat_gateway     = true
  enable_vpn_gateway     = true
}

module "ecr" {
  source = "../../modules/ecr"

  environment                     = "staging"
  allowed_account_ids            = [data.aws_caller_identity.current.account_id]
  allowed_principal_arns         = [module.iam.sagemaker_role_arn]
  notification_topic_arn         = module.sns.notification_topic_arn
  alarm_topic_arn               = module.sns.alarm_topic_arn
  cross_account_replication     = true
  replication_destination_registry = var.prod_account_id
}

module "sagemaker" {
  source = "../../modules/sagemaker"

  environment            = "staging"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  private_subnet_ids    = module.vpc.private_subnet_ids
  notebook_instance_type = var.notebook_instance_type
  notebook_volume_size  = var.notebook_volume_size
  data_bucket_arn      = module.s3.data_bucket_arn
  models_bucket_arn    = module.s3.models_bucket_arn
  s3_kms_key_arn      = module.s3.kms_key_arn
  enable_model_monitoring = true
}

module "lambda" {
  source = "../../modules/lambda"

  environment            = "staging"
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

  environment            = "staging"
  data_bucket_arn       = module.s3.data_bucket_arn
  models_bucket_arn     = module.s3.models_bucket_arn
  logs_bucket_arn       = module.s3.logs_bucket_arn
  s3_kms_key_arn       = module.s3.kms_key_arn
  sagemaker_kms_key_arn = module.sagemaker.kms_key_arn
  sagemaker_endpoint_arn = module.sagemaker.endpoint_arn
  enable_cross_account_access = true
  trusted_account_ids   = [var.prod_account_id]
}

data "aws_caller_identity" "current" {}