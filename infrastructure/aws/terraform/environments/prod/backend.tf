# infrastructure/aws/terraform/environments/prod/backend.tf

terraform {
  backend "s3" {
    bucket         = "layla-app-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "layla-app-terraform-locks-prod"
    kms_key_id     = "alias/terraform-state-key-prod"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.7"
}