output "rds_endpoint" {
  description = "RDS endpoint for the application"
  value       = aws_db_instance.rds_instance.address
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.rds_instance.endpoint
}

output "rds_password" {
  description = "RDS password"
  value       = random_password.rds_password.result
  sensitive   = true
}
