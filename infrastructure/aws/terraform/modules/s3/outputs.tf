# infrastructure/aws/terraform/modules/s3/outputs.tf

output "data_bucket" {
  description = "Data bucket details"
  value = {
    id  = aws_s3_bucket.data.id
    arn = aws_s3_bucket.data.arn
  }
}

output "models_bucket" {
  description = "Models bucket details"
  value = {
    id  = aws_s3_bucket.models.id
    arn = aws_s3_bucket.models.arn
  }
}

output "logs_bucket" {
  description = "Logs bucket details"
  value = {
    id  = aws_s3_bucket.logs.id
    arn = aws_s3_bucket.logs.arn
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption"
  value       = aws_kms_key.s3.arn
}