output "s3_bucket_name" {
  description = "S3 bucket name for states"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}
