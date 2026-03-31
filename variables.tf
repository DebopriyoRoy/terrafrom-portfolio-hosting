variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}
variable "key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
  default     = "ci-cd-keypair"
}
