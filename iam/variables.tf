variable "role_name" {
  description = "Name of the IAM role and instance profile."
  type        = string
  default     = "IAM-ROLE-FROM-JENKINS"
}

variable "role_description" {
  description = "Human-readable description for the IAM role."
  type        = string
  default     = "IAM role for ECS/EKS EC2 instances with required managed and inline policies."
}

variable "managed_policy_arns" {
  description = "List of AWS-managed policy ARNs to attach to the role."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AdministratorAccess", 
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default = {
    Project   = "ci-cd"
    ManagedBy = "terraform"
  }
}
