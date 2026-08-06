output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "targetgroup_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.tenant_tg.arn
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.test.arn
}