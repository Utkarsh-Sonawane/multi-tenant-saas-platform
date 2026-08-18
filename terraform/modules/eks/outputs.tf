output "environment" {
  description = "Environment name"
  value       = var.environment
}
output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.EKS_cluster.endpoint
}

output "oidc_issuer_url" {
  description = "OIDC issuer used for Kubernetes workload identity"
  value       = aws_eks_cluster.EKS_cluster.identity[0].oidc[0].issuer
}
