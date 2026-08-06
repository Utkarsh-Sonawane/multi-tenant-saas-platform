variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "igw_id" {
  description = "Internet Gateway ID"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}
