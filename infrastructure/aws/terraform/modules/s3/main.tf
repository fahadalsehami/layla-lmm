# infrastructure/aws/terraform/modules/s3/main.tf

provider "aws" {
  region = var.region
}

# KMS key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
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
      }
    ]
  })

  tags = {
    Name        = "layla-app-s3-kms-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/layla-app-s3-${var.environment}"
  target_key_id = aws_kms_key.s3.key_id
}

# Data bucket
resource "aws_s3_bucket" "data" {
  bucket = "layla-app-data-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "layla-app-data"
    Environment = var.environment
  }
}

# Models bucket
resource "aws_s3_bucket" "models" {
  bucket = "layla-app-models-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "layla-app-models"
    Environment = var.environment
  }
}

# Logs bucket
resource "aws_s3_bucket" "logs" {
  bucket = "layla-app-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "layla-app-logs"
    Environment = var.environment
  }
}

# Bucket configurations - Applied to all buckets
locals {
  buckets = {
    data   = aws_s3_bucket.data
    models = aws_s3_bucket.models
    logs   = aws_s3_bucket.logs
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = local.buckets
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  for_each = local.buckets
  
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  for_each = local.buckets
  
  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  for_each = local.buckets
  
  bucket = each.value.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Bucket policies
resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.data.arn,
          "${aws_s3_bucket.data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "models_bucket_policy" {
  bucket = aws_s3_bucket.models.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.models.arn,
          "${aws_s3_bucket.models.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# CORS configuration for data bucket
resource "aws_s3_bucket_cors_configuration" "data_cors" {
  bucket = aws_s3_bucket.data.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Enable bucket logging for data and models buckets
resource "aws_s3_bucket_logging" "data_logging" {
  bucket = aws_s3_bucket.data.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "data-bucket-logs/"
}

resource "aws_s3_bucket_logging" "models_logging" {
  bucket = aws_s3_bucket.models.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "models-bucket-logs/"
}

# CloudWatch metrics for monitoring
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  for_each = local.buckets

  alarm_name          = "layla-app-${each.key}-bucket-size-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "BucketSizeBytes"
  namespace          = "AWS/S3"
  period             = "86400"  # 1 day
  statistic          = "Maximum"
  threshold          = var.bucket_size_alarm_threshold
  alarm_description  = "This metric monitors S3 bucket size"
  alarm_actions      = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    BucketName = each.value.id
    StorageType = "StandardStorage"
  }

  tags = {
    Name        = "layla-app-${each.key}-bucket-size-alarm"
    Environment = var.environment
  }
}

# Data for current AWS account
data "aws_caller_identity" "current" {}