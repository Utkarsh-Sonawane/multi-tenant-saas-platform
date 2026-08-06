variable "private_subnet_ids" {
  type        = list(string)
  description = "Ids of the private subnets"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for the RDS security group"
}

variable "environment" {
  type = string
}