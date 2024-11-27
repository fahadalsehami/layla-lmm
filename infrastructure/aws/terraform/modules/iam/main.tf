# infrastructure/aws/terraform/modules/iam/main.tf

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
}

# Service Roles
## SageMaker Role
resource "aws_iam_role" "sagemaker" {
  name = "${local.name_prefix}-sagemaker-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sagemaker-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "sagemaker_s3" {
  name = "${local.name_prefix}-sagemaker-s3-policy-${var.environment}"
  role = aws_iam_role.sagemaker.id

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
          "${var.models_bucket_arn}/*",
          var.logs_bucket_arn,
          "${var.logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

## Lambda Role
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "lambda_vpc" {
  name = "${local.name_prefix}-lambda-vpc-policy-${var.environment}"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

## API Gateway Role
resource "aws_iam_role" "api_gateway" {
  name = "${local.name_prefix}-apigw-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-apigw-role-${var.environment}"
  })
}

## CloudWatch Role
resource "aws_iam_role" "cloudwatch" {
  name = "${local.name_prefix}-cloudwatch-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudwatch-role-${var.environment}"
  })
}

# Application Roles
## ML Pipeline Role
resource "aws_iam_role" "ml_pipeline" {
  name = "${local.name_prefix}-ml-pipeline-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "sagemaker.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ml-pipeline-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "ml_pipeline" {
  name = "${local.name_prefix}-ml-pipeline-policy-${var.environment}"
  role = aws_iam_role.ml_pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpoint",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:InvokeEndpoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
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
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          var.s3_kms_key_arn,
          var.sagemaker_kms_key_arn
        ]
      }
    ]
  })
}

## Data Processing Role
resource "aws_iam_role" "data_processor" {
  name = "${local.name_prefix}-data-processor-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-data-processor-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "data_processor" {
  name = "${local.name_prefix}-data-processor-policy-${var.environment}"
  role = aws_iam_role.data_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpoint"
        ]
        Resource = var.sagemaker_endpoint_arn
      }
    ]
  })
}

## Monitoring Role
resource "aws_iam_role" "monitoring" {
  name = "${local.name_prefix}-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "cloudwatch.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-monitoring-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "monitoring" {
  name = "${local.name_prefix}-monitoring-policy-${var.environment}"
  role = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy Attachments
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Cross-Account Access (if needed)
resource "aws_iam_role" "cross_account" {
  count = var.enable_cross_account_access ? 1 : 0
  
  name = "${local.name_prefix}-cross-account-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = var.trusted_account_ids
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cross-account-role-${var.environment}"
  })
}
