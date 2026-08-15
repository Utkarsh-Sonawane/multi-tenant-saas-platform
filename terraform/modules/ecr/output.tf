output "repo_name" {
  value = aws_ecr_repository.multi-tenant-app.name
}

<<<<<<< HEAD
=======
<<<<<<< HEAD
output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.multi-tenant-app.repository_url
=======
>>>>>>> my-temp-branch
output "repo_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
}

output "repository_url" {
  value = aws_ecr_repository.multi-tenant-app.repository_url
<<<<<<< HEAD
=======
>>>>>>> 06fe304 (add new code)
>>>>>>> my-temp-branch
}