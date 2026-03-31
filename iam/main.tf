# ==============================================================================
# IAM ROLE  —  ecsInstanceRole
# Trust policy allows EC2 instances to assume this role
# ==============================================================================
resource "aws_iam_role" "this" {
  name        = var.role_name
  description = var.role_description
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

# ==============================================================================
# AWS MANAGED POLICY ATTACHMENTS
# Visible in the console as "AWS managed" type:
#   - AdministratorAccess
#   - AmazonEC2ContainerServiceRole
#   - AmazonEC2FullAccess
#   - AmazonEKSClusterPolicy
#   - AmazonSSMManagedInstanceCore
# ==============================================================================
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# ==============================================================================
# CUSTOMER INLINE POLICY — eks-policy-creation
# Grants basic EKS read permissions (DescribeCluster, ListClusters)
# ==============================================================================
resource "aws_iam_role_policy" "eks_policy_creation" {
  name = "eks-policy-creation"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:TagResource",
          "eks:UntagResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# CUSTOMER INLINE POLICY — EKSClusterPolicy
# Shown expanded in the console — allows DescribeCluster and ListClusters
# ==============================================================================
resource "aws_iam_role_policy" "eks_cluster_policy" {
  name = "EKSClusterPolicy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# CUSTOMER INLINE POLICY — iam-policy-creation
# Shown expanded in the console — grants IAM + OIDC provider management rights
# needed by EKS to create service-linked roles and OIDC providers
# ==============================================================================
resource "aws_iam_role_policy" "iam_policy_creation" {
  name = "iam-policy-creation"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:PassRole",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:CreateServiceLinkedRole",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# INSTANCE PROFILE
# Wraps the role so EC2 instances can assume it at launch
# ==============================================================================
resource "aws_iam_instance_profile" "this" {
  name = var.role_name
  role = aws_iam_role.this.name

  tags = var.tags
}
