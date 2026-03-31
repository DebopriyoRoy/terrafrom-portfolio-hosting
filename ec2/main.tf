# ==============================================================================
# EC2 INSTANCE — crtd-from-jenkins
# Placed inside the crt-from-jenkins VPC (public subnet), attached to the
# ec2-from-jenkins IAM instance profile and the VPC security group.
# ==============================================================================
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type

  # Subnet from the vpc module (public subnet in us-east-1a)
  subnet_id = var.subnet_id

  # Security group from the vpc module
  vpc_security_group_ids = var.vpc_security_group_ids

  # IAM instance profile from the iam module (ec2-from-jenkins)
  iam_instance_profile = var.iam_instance_profile

  # Assign a public IP explicitly
  associate_public_ip_address = true
  key_name = var.key_name

  root_block_device {          
    volume_type           = "gp2"
    volume_size           = 24    # GB — minimum 24
    delete_on_termination = true  # cleans up the volume when the instance is destroyed
  }

  tags = {
    Name      = "terraform-from-jenkins"
    Project   = "ci-cd"
    ManagedBy = "terraform"
  }
}
