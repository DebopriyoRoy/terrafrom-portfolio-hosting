output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.vpc_inst.id
}

output "vpc_cidr" {
  description = "Primary IPv4 CIDR block of the VPC."
  value       = aws_vpc.vpc_inst.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.vpc_inst.id
}

output "public_subnet_ids" {
  description = "Map of public subnet name → subnet ID."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet name → subnet ID."
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "public_subnet_ids_list" {
  description = "Ordered list of public subnet IDs."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids_list" {
  description = "Ordered list of private subnet IDs."
  value       = [for s in aws_subnet.private : s.id]
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of private subnet name → private route table ID."
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group — consumed by the ec2 module."
  value       = aws_security_group.ec2.id
}
