output "repo_name" {
  value = aws_ecr_repository.multi-tenant-app.name
}

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.multi-tenant-app.repository_url
}