variable "vpc_name" {
  description = "Name of the VPC; used as prefix for all child resources."
  type        = string
  default     = "crt-from-jenkins"
}

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS region — used to build the S3 VPC endpoint service name."
  type        = string
  default     = "us-east-1"
}

# ------------------------------------------------------------------------------
# Public subnets — named to match the resource map in the image
# crt-from-jenkins-subnet-public1-us-east-1a  →  us-east-1a
# crt-from-jenkins-subnet-public2-us-east-1b  →  us-east-1b
# ------------------------------------------------------------------------------
variable "public_subnets" {
  description = "List of public subnet definitions. Each object needs name, cidr, and az."
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  default = [
    {
      name = "crt-from-jenkins-subnet-public1-us-east-1a"
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
    },
    {
      name = "crt-from-jenkins-subnet-public2-us-east-1b"
      cidr = "10.0.2.0/24"
      az   = "us-east-1b"
    }
  ]
}

# ------------------------------------------------------------------------------
# Private subnets
# crt-from-jenkins-subnet-private1-us-east-1a  →  us-east-1a
# crt-from-jenkins-subnet-private2-us-east-1b  →  us-east-1b
# ------------------------------------------------------------------------------
variable "private_subnets" {
  description = "List of private subnet definitions. Each object needs name, cidr, and az."
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  default = [
    {
      name = "crt-from-jenkins-subnet-private1-us-east-1a"
      cidr = "10.0.3.0/24"
      az   = "us-east-1a"
    },
    {
      name = "crt-from-jenkins-subnet-private2-us-east-1b"
      cidr = "10.0.4.0/24"
      az   = "us-east-1b"
    }
  ]
}

# ------------------------------------------------------------------------------
# SSH access — restricted to your IP only
# Only 193.149.173.67 can SSH into the EC2 instance on port 22.
# If your IP changes, update this value and re-run the pipeline.
# ------------------------------------------------------------------------------
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the EC2 instance."
  type        = list(string)
  default     = ["193.149.173.67/32"]
}

variable "tags" {
  description = "Tags merged onto every resource in this module."
  type        = map(string)
  default = {
    Project   = "ci-cd"
    ManagedBy = "terraform"
  }
}
