variable "bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string
  default     = "cicd-jenkins-debopriyoroy-2026"
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket — keeps all object versions for rollback."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    Project   = "ci-cd"
    ManagedBy = "terraform"
  }
}
