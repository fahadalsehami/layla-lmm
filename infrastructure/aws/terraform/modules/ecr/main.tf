# infrastructure/aws/terraform/modules/ecr/main.tf

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

  # Define repository configurations
  repositories = {
    ml_model = {
      name        = "ml-model"
      description = "ML model containers"
      scan_on_push = true
      force_delete = false
      expiration_days = 30
    }
    feature_extractor = {
      name        = "feature-extractor"
      description = "Feature extraction service"
      scan_on_push = true
      force_delete = false
      expiration_days = 30
    }
    biomarker_processor = {
      name        = "biomarker-processor"
      description = "Biomarker processing service"
      scan_on_push = true
      force_delete = false
      expiration_days = 30
    }
    inference_api = {
      name        = "inference-api"
      description = "Model inference API"
      scan_on_push = true
      force_delete = false
      expiration_days = 30
    }
    data_processor = {
      name        = "data-processor"
      description = "Data processing service"
      scan_on_push = true
      force_delete = false
      expiration_days = 30
    }
  }
}

# KMS Key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
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
        Sid    = "Allow ECR to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
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
    Name = "${local.name_prefix}-ecr-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.name_prefix}-ecr-${var.environment}"
  target_key_id = aws_kms_key.ecr.key_id
}

# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = local.repositories

  name                 = "${local.name_prefix}-${each.value.name}-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key        = aws_kms_key.ecr.arn
  }

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  force_delete = each.value.force_delete

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-${each.value.name}-${var.environment}"
    Description = each.value.description
  })
}

# Repository Policies
resource "aws_ecr_repository_policy" "policies" {
  for_each = local.repositories

  repository = aws_ecr_repository.repositories[each.key].name
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_account_ids
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPush"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principal_arns
        }
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "policies" {
  for_each = local.repositories

  repository = aws_ecr_repository.repositories[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${each.value.expiration_days} days of images"
        selection = {
          tagStatus     = "any"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = each.value.expiration_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# CloudWatch Event Rules for ECR Scanning
resource "aws_cloudwatch_event_rule" "ecr_scan" {
  for_each = {
    for k, v in local.repositories : k => v
    if v.scan_on_push
  }

  name        = "${local.name_prefix}-${each.value.name}-scan-${var.environment}"
  description = "Capture ECR scan findings"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Scan"]
    detail = {
      repository-name = [aws_ecr_repository.repositories[each.key].name]
      scan-status    = ["COMPLETE"]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}-scan-rule-${var.environment}"
  })
}

resource "aws_cloudwatch_event_target" "ecr_scan_notification" {
  for_each = aws_cloudwatch_event_rule.ecr_scan

  rule      = each.value.name
  target_id = "SendToSNS"
  arn       = var.notification_topic_arn

  input_transformer {
    input_paths = {
      repository = "$.detail.repository-name"
      tag        = "$.detail.image-tags[0]"
      findings   = "$.detail.finding-severity-counts"
    }
    input_template = "ECR Scan completed for repository <repository> tag <tag>. Findings: <findings>"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "image_scan_findings" {
  for_each = aws_ecr_repository.repositories

  alarm_name          = "${each.value.name}-critical-vulnerabilities-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "ImageScanFindingsSeverityCount"
  namespace          = "AWS/ECR"
  period             = "300"
  statistic          = "Maximum"
  threshold          = "0"
  alarm_description  = "This metric monitors critical vulnerabilities in container images"

  dimensions = {
    Repository = each.value.name
    SeverityCount = "CRITICAL"
  }

  alarm_actions = [var.alarm_topic_arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}-alarm-${var.environment}"
  })
}

# Data for current AWS account
data "aws_caller_identity" "current" {}