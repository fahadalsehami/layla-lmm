# infrastructure/aws/terraform/environments/staging/backend.tf

terraform {
  backend "s3" {
    bucket         = "layla-app-terraform-state-staging"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "layla-app-terraform-locks-staging"
    kms_key_id     = "alias/terraform-state-key-staging"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.7"
}