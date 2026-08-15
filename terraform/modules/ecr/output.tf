output "repo_name" {
  value = aws_ecr_repository.multi-tenant-app.name
}

<<<<<<< HEAD
output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.multi-tenant-app.repository_url
=======
output "repo_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
}

output "repository_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
>>>>>>> 06fe304 (add new code)
}