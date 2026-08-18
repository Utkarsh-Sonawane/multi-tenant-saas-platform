variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}
variable "aws_region" {
  description = "AWS region"

  type = string
}
variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}
#variable "aws_access_key" {
#  description = "AWS access key"
#  type        = string
#}
#variable "aws_secret_key" {
#  description = "AWS secret key"
#  type        = string
#}