output "repo_name" {
  value = aws_ecr_repository.multi-tenant-app.name
}

output "repo_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
}

output "repository_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
}