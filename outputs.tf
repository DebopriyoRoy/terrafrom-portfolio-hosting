output "instance_id" {
  description = "ID of the crtd-from-jenkins EC2 instance."
  value = module.ec2_instance.instance_id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = module.ec2_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance inside the VPC."
  value       = module.ec2_instance.private_ip
}
output "s3_bucket_name" {
  description = "Name of the S3 bucket."
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = module.s3.bucket_arn
}
