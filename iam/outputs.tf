# ==============================================================================
# IAM ROLE
# ==============================================================================
output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role — use this when a service needs to reference the role."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "Unique ID of the IAM role."
  value       = aws_iam_role.this.id
}

# ==============================================================================
# INSTANCE PROFILE
# ==============================================================================
output "instance_profile_name" {
  description = "Name of the IAM instance profile — pass to aws_launch_template or aws_instance."
  value       = aws_iam_instance_profile.this.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile."
  value       = aws_iam_instance_profile.this.arn
}

# ==============================================================================
# INLINE POLICIES
# ==============================================================================
output "inline_policy_eks_policy_creation" {
  description = "Name of the eks-policy-creation inline policy."
  value       = aws_iam_role_policy.eks_policy_creation.name
}

output "inline_policy_eks_cluster_policy" {
  description = "Name of the EKSClusterPolicy inline policy."
  value       = aws_iam_role_policy.eks_cluster_policy.name
}

output "inline_policy_iam_policy_creation" {
  description = "Name of the iam-policy-creation inline policy."
  value       = aws_iam_role_policy.iam_policy_creation.name
}
