terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52"
    }
  }
}
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
module "vpc" {
  source = "../../modules/vpc"
  environment = "prod"
  cidr_block = var.cidr_block
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
}
module "eks" {
  source = "../../modules/eks"
  environment = "prod"
  private_subnet_ids = module.vpc.private_subnet_ids
}
module "rds" {
  source = "../../modules/rds"
  environment = "prod"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id = module.vpc.aws_vpc_id
}
module "ecr" {
  source = "../../modules/ecr"
  environment = "prod"
}

#module "alb" {
#  source = "../../modules/alb"
#  environment = "prod"
#  vpc_id = module.vpc.aws_vpc_id
#  public_subnet_ids = module.vpc.public_subnet_ids
#}