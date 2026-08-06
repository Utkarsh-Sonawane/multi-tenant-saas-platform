terraform {
  required_version = ">= 1.5.0"
}

module "vpc" {
  source = "../../modules/vpc"

  environment                 = var.environment
  cidr_block                  = var.cidr_block
  public_subnet_cidr_blocks   = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks  = var.private_subnet_cidr_blocks
}
