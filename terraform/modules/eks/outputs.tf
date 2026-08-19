output "environment" {
  description = "Environment name"
  value       = var.environment
}
output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.EKS_cluster.endpoint 
}