# ==============================================================================
# S3 BUCKET — crt-from-jenkins-bucket
# Private bucket for CI/CD artifacts, terraform state, and app data.
# Versioning enabled so every object upload is preserved.
# Server-side encryption (AES-256) enabled by default.
# Public access fully blocked — bucket is private.
# ==============================================================================
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

# ==============================================================================
# VERSIONING
# Keeps every version of every object — allows rollback of artifacts
# ==============================================================================
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
  status     = var.versioning_enabled ? "Enabled" : "Suspended"
  mfa_delete = "Disabled"
}
}

# ==============================================================================
# SERVER-SIDE ENCRYPTION — AES-256 (SSE-S3, free, no KMS cost)
# ==============================================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==============================================================================
# BLOCK ALL PUBLIC ACCESS
# Prevents accidental public exposure of CI/CD artifacts
# ==============================================================================
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# LIFECYCLE RULE
# Automatically moves old artifact versions to cheaper storage after 30 days
# and permanently deletes non-current versions after 90 days
# ==============================================================================
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "artifact-lifecycle"
    status = "Enabled"
    filter {}
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
