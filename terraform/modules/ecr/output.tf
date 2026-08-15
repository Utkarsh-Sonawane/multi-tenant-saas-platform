output "repo_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.multi-tenant-app.name
}

output "repo_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.multi-tenant-app.repository_url
}

output "repository_url" {
  description = "ECR repository URL for CI/CD consumers"
  value       = aws_ecr_repository.multi-tenant-app.repository_url
}