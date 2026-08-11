resource "aws_kms_key" "key_ecr" {
    description             = "KMS key for ECR encryption"
    deletion_window_in_days = 30
    tags = {
        Name        = "ecr-kms-key"
        Environment = var.environment
    }
}

resource "aws_kms_alias" "alias_ecr" {
    name          = "alias/ecr"
    target_key_id = aws_kms_key.key_ecr.id
}

resource "aws_ecr_repository" "multi-tenant-app" {
  name                 = "multi-tenant-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.key_ecr.arn
  }
  tags = {
    Name        = "multi-tenant-app"
    Environment = var.environment
  }
}

