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
  value = module.eks.cluster_endpoint
  description = "The endpoint for the EKS cluster"
 }
 #output "alb_arn" {
 # value = module.alb.alb_arn
 # description = "The ARN of the ALB"
 #}
 # output "targetgroup_arn" {
 # value = module.alb.targetgroup_arn  
 # }
  output "rds_endpoint" {
  value = module.rds.rds_endpoint
  }
  output "ecr_name" {
  value = module.ecr.repo_name
  }
<<<<<<< HEAD
=======
<<<<<<< HEAD
  # Expose the ECR repository URL for external consumers (CI/CD)
  output "ecr_repository_url" {
    description = "Fully qualified ECR repository URL (account.dkr.ecr.region.amazonaws.com/repo)"
    value       = module.ecr.repository_url
=======
>>>>>>> my-temp-branch

  output "ecr_url" {
  value = module.ecr.repo_url
  }

  output "ecr_repository_url" {
  value = module.ecr.repo_url
  }
  
  output "rds_password" {
  value = module.rds.rds_password
<<<<<<< HEAD
=======
>>>>>>> 06fe304 (add new code)
>>>>>>> my-temp-branch
  }