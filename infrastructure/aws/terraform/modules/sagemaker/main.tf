# infrastructure/aws/terraform/modules/sagemaker/main.tf

provider "aws" {
  region = var.region
}

locals {
  name_prefix = "layla-app"
  
  common_tags = {
    Project     = "layla-app"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  ecr_repositories = [
    "custom-model",
    "model-monitor",
    "feature-processor",
    "training"
  ]
}

# KMS key for encryption
resource "aws_kms_key" "sagemaker" {
  description             = "KMS key for SageMaker encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow SageMaker to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sagemaker-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "sagemaker" {
  name          = "alias/${local.name_prefix}-sagemaker-${var.environment}"
  target_key_id = aws_kms_key.sagemaker.key_id
}

# Security Group for SageMaker
resource "aws_security_group" "sagemaker" {
  name        = "${local.name_prefix}-sagemaker-sg-${var.environment}"
  description = "Security group for SageMaker resources"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sagemaker-sg-${var.environment}"
  })
}

# SageMaker Domain
resource "aws_sagemaker_domain" "main" {
  domain_name = "${local.name_prefix}-domain-${var.environment}"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids

  default_user_settings {
    execution_role = aws_iam_role.sagemaker.arn
    
    security_groups = [aws_security_group.sagemaker.id]

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = var.notebook_instance_type
        volume_size_in_gb = var.notebook_volume_size
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = var.notebook_instance_type
        volume_size_in_gb = var.notebook_volume_size
      }
    }
  }

  retention_policy {
    home_efs_file_system = "Delete"
  }

  domain_settings {
    execution_role_identity_config = "USER_PROFILE_NAME"
    security_group_ids            = [aws_security_group.sagemaker.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-domain-${var.environment}"
  })
}

# SageMaker User Profile
resource "aws_sagemaker_user_profile" "main" {
  domain_id         = aws_sagemaker_domain.main.id
  user_profile_name = "${local.name_prefix}-user-${var.environment}"

  user_settings {
    execution_role = aws_iam_role.sagemaker.arn
    
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = var.notebook_instance_type
        volume_size_in_gb = var.notebook_volume_size
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-user-profile-${var.environment}"
  })
}

# SageMaker App
resource "aws_sagemaker_app" "jupyter" {
  domain_id         = aws_sagemaker_domain.main.id
  user_profile_name = aws_sagemaker_user_profile.main.user_profile_name
  app_name         = "default"
  app_type         = "JupyterServer"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jupyter-app-${var.environment}"
  })
}

# ECR Repositories
resource "aws_ecr_repository" "sagemaker" {
  for_each = toset(local.ecr_repositories)

  name                 = "${local.name_prefix}-${each.key}-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key        = aws_kms_key.sagemaker.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-${var.environment}"
  })
}

# Model Package Group
resource "aws_sagemaker_model_package_group" "main" {
  model_package_group_name = "${local.name_prefix}-models-${var.environment}"
  model_package_group_description = "Model registry for Layla App"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-model-registry-${var.environment}"
  })
}

# Data for current AWS account
data "aws_caller_identity" "current" {}
