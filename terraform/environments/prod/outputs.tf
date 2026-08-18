output "environment" {
  description = "The active environment"
  value       = var.environment
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.aws_vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  value       = module.vpc.private_subnet_ids
}

output "cluster" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "ecr_name" {
  description = "ECR repository name"
  value       = module.ecr.repo_name
}

output "ecr_url" {
  description = "ECR repository URL"
  value       = module.ecr.repo_url
}

output "ecr_repository_url" {
  description = "Fully qualified ECR repository URL for CI/CD"
  value       = module.ecr.repository_url
}

output "rds_password" {
  description = "RDS password"
  value       = module.rds.rds_password
  sensitive   = true
}

output "bootstrap_ssm_role_arn" { value = aws_iam_role.ssm_reader["bootstrap"].arn }
output "tenant_a_ssm_role_arn" { value = aws_iam_role.ssm_reader["tenant_a"].arn }
output "tenant_b_ssm_role_arn" { value = aws_iam_role.ssm_reader["tenant_b"].arn }
output "tenant_c_ssm_role_arn" { value = aws_iam_role.ssm_reader["tenant_c"].arn }
