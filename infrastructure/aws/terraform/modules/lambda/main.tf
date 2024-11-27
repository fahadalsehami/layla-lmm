# infrastructure/aws/terraform/modules/lambda/main.tf

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

  lambda_functions = {
    biomarker_processor = {
      name        = "biomarker-processor"
      handler     = "main.handler"
      memory      = 1024
      timeout     = 300
      runtime     = "python3.9"
      concurrent  = 10
    }
    feature_extractor = {
      name        = "feature-extractor"
      handler     = "main.handler"
      memory      = 2048
      timeout     = 600
      runtime     = "python3.9"
      concurrent  = 5
    }
    model_inference = {
      name        = "model-inference"
      handler     = "main.handler"
      memory      = 3072
      timeout     = 900
      runtime     = "python3.9"
      concurrent  = 20
    }
    data_preprocessor = {
      name        = "data-preprocessor"
      handler     = "main.handler"
      memory      = 1024
      timeout     = 300
      runtime     = "python3.9"
      concurrent  = 5
    }
  }
}

# KMS Key for Lambda encryption
resource "aws_kms_key" "lambda" {
  description             = "KMS key for Lambda functions encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid       = "Allow Lambda to use the key"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
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
    Name = "${local.name_prefix}-lambda-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "lambda" {
  name          = "alias/${local.name_prefix}-lambda-${var.environment}"
  target_key_id = aws_kms_key.lambda.key_id
}

# Security Group for Lambda
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg-${var.environment}"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound HTTPS"
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
    Name = "${local.name_prefix}-lambda-sg-${var.environment}"
  })
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-role-${var.environment}"
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*",
          var.models_bucket_arn,
          "${var.models_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpoint",
          "sagemaker:DescribeEndpoint"
        ]
        Resource = var.sagemaker_endpoint_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.lambda.arn,
          var.s3_kms_key_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  filename         = var.lambda_source_path
  function_name    = "${local.name_prefix}-${each.value.name}-${var.environment}"
  role            = aws_iam_role.lambda.arn
  handler         = each.value.handler
  runtime         = each.value.runtime
  memory_size     = each.value.memory
  timeout         = each.value.timeout

  environment {
    variables = merge(var.common_environment_variables, {
      ENVIRONMENT        = var.environment
      SAGEMAKER_ENDPOINT = var.sagemaker_endpoint_name
      DATA_BUCKET        = var.data_bucket_name
      MODELS_BUCKET      = var.models_bucket_name
      KMS_KEY_ARN       = aws_kms_key.lambda.arn
    })
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  reserved_concurrent_executions = each.value.concurrent

  tracing_config {
    mode = "Active"
  }

  layers = var.lambda_layer_arns

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}-${var.environment}"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${local.name_prefix}-${each.value.name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id       = aws_kms_key.lambda.arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}-logs-${var.environment}"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = local.lambda_functions

  alarm_name          = "${local.name_prefix}-${each.value.name}-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "Errors"
  namespace          = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "1"
  alarm_description  = "Lambda function error rate monitor"
  alarm_actions      = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.functions[each.key].function_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}-alarm-${var.environment}"
  })
}

# Data for current AWS account
data "aws_caller_identity" "current" {}