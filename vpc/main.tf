# ==============================================================================
# VPC — crt-from-jenkins
# ==============================================================================
resource "aws_vpc" "vpc_inst" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

# ==============================================================================
# INTERNET GATEWAY — crt-from-jenkins-igw
# ==============================================================================
resource "aws_internet_gateway" "vpc_inst" {
  vpc_id = aws_vpc.vpc_inst.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# ==============================================================================
# PUBLIC SUBNETS
# crt-from-jenkins-subnet-public1-us-east-1a
# crt-from-jenkins-subnet-public2-us-east-1b
# ==============================================================================
resource "aws_subnet" "public" {
  for_each = { for s in var.public_subnets : s.name => s }

  vpc_id                  = aws_vpc.vpc_inst.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.value.name
    Tier = "public"
  })
}

# ==============================================================================
# PRIVATE SUBNETS
# crt-from-jenkins-subnet-private1-us-east-1a
# crt-from-jenkins-subnet-private2-us-east-1b
# ==============================================================================
resource "aws_subnet" "private" {
  for_each = { for s in var.private_subnets : s.name => s }

  vpc_id            = aws_vpc.vpc_inst.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.value.name
    Tier = "private"
  })
}

# ==============================================================================
# PUBLIC ROUTE TABLE — crt-from-jenkins-rtb-public
# Routes all egress through the Internet Gateway
# ==============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_inst.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_inst.id
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-rtb-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# PRIVATE ROUTE TABLES — one per AZ, local traffic only
# crt-from-jenkins-rtb-crt-from-jenkins-subnet-private1-us-east-1a
# crt-from-jenkins-rtb-crt-from-jenkins-subnet-private2-us-east-1b
# ==============================================================================
resource "aws_route_table" "private" {
  for_each = { for s in var.private_subnets : s.name => s }

  vpc_id = aws_vpc.vpc_inst.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-rtb-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ==============================================================================
# S3 VPC ENDPOINT — crt-from-jenkins-vpce-s3
# Gateway type (free). Keeps S3 traffic on the AWS backbone.
# Attached to all route tables — public and private.
# ==============================================================================
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_inst.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [for rt in aws_route_table.private : rt.id]
  )

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-vpce-s3"
  })
}

# ==============================================================================
# SECURITY GROUP — crt-from-jenkins-ec2-sg
# Attached to the EC2 instance by the root module.
# Ingress: SSH (22), HTTP (80), HTTPS (443)
# Egress:  all outbound allowed
# ==============================================================================
resource "aws_security_group" "ec2" {
  name        = "${var.vpc_name}-ec2-sg"
  description = "Security group for the crtd-from-jenkins EC2 instance"
  vpc_id      = aws_vpc.vpc_inst.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "Nexus"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }
  
  ingress {
    description = "Sonarqube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-ec2-sg"
  })
}
