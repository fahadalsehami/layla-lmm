# infrastructure/aws/terraform/environments/dev/backend.tf

terraform {
  backend "s3" {
    bucket         = "layla-app-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "layla-app-terraform-locks-dev"
    kms_key_id     = "alias/terraform-state-key-dev"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.7"
}
