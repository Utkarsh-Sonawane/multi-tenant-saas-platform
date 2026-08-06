variable "environment" {
  description = "Environment name"
  type        = string
}
variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS module"
  type        = list(string)
}
