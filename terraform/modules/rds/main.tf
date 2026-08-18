resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "rds_instance" {
  identifier = "demodb"

  engine            = "postgres"
  engine_version    = "14.9"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name  = "demodb"
  username = "admin"
  port     = "5432"
  password = "${random_password.rds_password.result}"
  

  iam_database_authentication_enabled = true
  db_subnet_group_name                = aws_db_subnet_group.rds.name
  vpc_security_group_ids             = [aws_security_group.rds.id]
  skip_final_snapshot                = true
  deletion_protection                = false

  tags = {
    Owner       = "Master_db"
    Environment = "var"
  }
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/myapp/${var.environment}/rds_endpoint"
  description = "RDS endpoint for ${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.rds_instance.endpoint
  overwrite   = true
}

resource "aws_ssm_parameter" "rds_pass" {
  name        = "/myapp/${var.environment}/rds_password"
  description = "RDS password for ${var.environment}"
  type        = "SecureString"
  value       = random_password.rds_password.result
  overwrite   = true
}