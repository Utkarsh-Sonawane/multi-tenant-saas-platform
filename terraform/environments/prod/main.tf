terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "tenant-tfstate-ap-south-1"
    key    = "prod/terraform.tfstate" # Unique state path for prod
    region = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
}
module "vpc" {
  source                     = "../../modules/vpc"
  environment                = "prod"
  cidr_block                 = var.cidr_block
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
}
module "eks" {
  source             = "../../modules/eks"
  environment        = "prod"
  private_subnet_ids = module.vpc.private_subnet_ids
}
module "rds" {
  source             = "../../modules/rds"
  environment        = "prod"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.aws_vpc_id
}
module "ecr" {
  source      = "../../modules/ecr"
  environment = "prod"
}

data "tls_certificate" "eks_oidc" {
  url = module.eks.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = module.eks.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

locals {
  secret_readers = {
    bootstrap = { namespace = "tenant-a", service_account = "db-bootstrap-secrets-reader", paths = ["/myapp/prod/rds_endpoint", "/multi-tenant/prod/rds/*", "/multi-tenant/prod/config-db/password", "/multi-tenant/prod/tenant-*/db/password"] }
    tenant_a  = { namespace = "tenant-a", service_account = "tenant-a-secrets-reader", paths = ["/myapp/prod/rds_endpoint", "/multi-tenant/prod/config-db/password", "/multi-tenant/prod/tenant-a/*"] }
    tenant_b  = { namespace = "tenant-b", service_account = "tenant-b-secrets-reader", paths = ["/myapp/prod/rds_endpoint", "/multi-tenant/prod/config-db/password", "/multi-tenant/prod/tenant-b/*"] }
    tenant_c  = { namespace = "tenant-c", service_account = "tenant-c-secrets-reader", paths = ["/myapp/prod/rds_endpoint", "/multi-tenant/prod/config-db/password", "/multi-tenant/prod/tenant-c/*"] }
  }
}

resource "aws_iam_role" "ssm_reader" {
  for_each           = local.secret_readers
  name               = "multi-tenant-${each.key}-ssm-reader"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "sts:AssumeRoleWithWebIdentity", Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }, Condition = { StringEquals = { "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}", "${replace(module.eks.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com" } } }] })
}

resource "aws_iam_role_policy" "ssm_reader" {
  for_each = local.secret_readers
  role     = aws_iam_role.ssm_reader[each.key].id
  policy   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters"], Resource = [for path in each.value.paths : "arn:aws:ssm:${var.aws_region}:*:parameter${path}"] }] })
}

#module "alb" {
#  source = "../../modules/alb"
#  environment = "prod"
#  vpc_id = module.vpc.aws_vpc_id
#  public_subnet_ids = module.vpc.public_subnet_ids
#}
