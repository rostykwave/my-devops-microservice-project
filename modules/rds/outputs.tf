output "endpoint" {
  description = "The connection endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].address
}

output "reader_endpoint" {
  description = "The reader endpoint (Aurora only)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "port" {
  description = "The database port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "db_name" {
  description = "The database name"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].database_name : aws_db_instance.standard[0].db_name
}

output "master_username" {
  description = "The master username"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].master_username : aws_db_instance.standard[0].username
}
