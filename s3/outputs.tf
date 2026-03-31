output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket — use in IAM policies to grant access."
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket (same as bucket name)."
  value       = aws_s3_bucket.this.id
}

output "bucket_domain_name" {
  description = "Bucket domain name for use in application config."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name — use this for VPC endpoint routing."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
