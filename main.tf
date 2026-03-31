terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# VPC MODULE — creates crt-from-jenkins VPC + subnets + IGW + route tables
#              + S3 endpoint + security group
# ==============================================================================
module "vpc_inst" {
  source     = "./vpc"
  aws_region = var.aws_region
}

# ==============================================================================
# IAM MODULE — creates ec2-from-jenkins role + instance profile
# ==============================================================================
module "iam" {
  source = "./iam"
}

# ==============================================================================
# EC2 MODULE — creates crtd-from-jenkins instance wired into VPC + IAM
# ==============================================================================
module "ec2_instance" {
  source = "./ec2"

  subnet_id              = module.vpc_inst.public_subnet_ids_list[0]
  vpc_security_group_ids = [module.vpc_inst.ec2_security_group_id]
  iam_instance_profile   = module.iam.instance_profile_name
}
# ==============================================================================
# S3 MODULE — creates crt-from-jenkins-bucket
# Private, encrypted, versioned bucket for CI/CD artifacts and app data.
# Accessible from EC2 via the S3 VPC endpoint — no public internet needed.
# ==============================================================================
module "s3" {
  source = "./s3"
}
