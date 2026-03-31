variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance."
  type        = string
  default     = "ami-0f3caa1cf4417e51b"
}

variable "subnet_id" {
  description = "Public subnet ID from the vpc module to launch the instance into."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs from the vpc module to attach to the instance."
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair name"
  default = "ci-cd-keypair"
  type        = string
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile from the iam module (ec2-from-jenkins)."
  type        = string
}
