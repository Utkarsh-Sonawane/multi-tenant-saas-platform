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

resource "random_password" "config_db_password" {
  length  = 32
  special = true
}

resource "random_password" "tenant_db_password" {
  for_each = toset(["tenant-a", "tenant-b", "tenant-c"])
  length   = 32
  special  = true
}

resource "random_password" "tenant_flask_secret" {
  for_each = toset(["tenant-a", "tenant-b", "tenant-c"])
  length   = 48
  special  = true
}

resource "aws_db_instance" "rds_instance" {
  identifier = "demodb"

  engine            = "postgres"
  engine_version    = "14.22"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "demodb"
  username          = "dbadmin"
  port              = "5432"
  password          = random_password.rds_password.result


  iam_database_authentication_enabled = true
  db_subnet_group_name                = aws_db_subnet_group.rds.name
  vpc_security_group_ids              = [aws_security_group.rds.id]
  skip_final_snapshot                 = true
  deletion_protection                 = false

  tags = {
    Owner       = "Master_db"
    Environment = "var.environment"
  }
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/myapp/${var.environment}/rds_endpoint"
  description = "RDS endpoint for ${var.environment}"
  type        = "SecureString"
  value       = aws_db_instance.rds_instance.address
  overwrite   = true
}

resource "aws_ssm_parameter" "rds_pass" {
  name        = "/myapp/${var.environment}/rds_password"
  description = "RDS password for ${var.environment}"
  type        = "SecureString"
  value       = random_password.rds_password.result
  overwrite   = true
}

resource "aws_ssm_parameter" "rds_port" {
  name      = "/multi-tenant/${var.environment}/rds/port"
  type      = "String"
  value     = tostring(aws_db_instance.rds_instance.port)
  overwrite = true
}

resource "aws_ssm_parameter" "rds_master_username" {
  name      = "/multi-tenant/${var.environment}/rds/master/username"
  type      = "SecureString"
  value     = aws_db_instance.rds_instance.username
  overwrite = true
}

resource "aws_ssm_parameter" "rds_master_password" {
  name      = "/multi-tenant/${var.environment}/rds/master/password"
  type      = "SecureString"
  value     = random_password.rds_password.result
  overwrite = true
}

resource "aws_ssm_parameter" "config_db_username" {
  name      = "/multi-tenant/${var.environment}/config-db/username"
  type      = "String"
  value     = "config_user"
  overwrite = true
}

resource "aws_ssm_parameter" "config_db_password" {
  name      = "/multi-tenant/${var.environment}/config-db/password"
  type      = "SecureString"
  value     = random_password.config_db_password.result
  overwrite = true
}

resource "aws_ssm_parameter" "tenant_db_username" {
  for_each  = random_password.tenant_db_password
  name      = "/multi-tenant/${var.environment}/${each.key}/db/username"
  type      = "String"
  value     = replace(each.key, "-", "_") + "_user"
  overwrite = true
}

resource "aws_ssm_parameter" "tenant_db_password" {
  for_each  = random_password.tenant_db_password
  name      = "/multi-tenant/${var.environment}/${each.key}/db/password"
  type      = "SecureString"
  value     = each.value.result
  overwrite = true
}

resource "aws_ssm_parameter" "tenant_flask_secret" {
  for_each  = random_password.tenant_flask_secret
  name      = "/multi-tenant/${var.environment}/${each.key}/flask-secret"
  type      = "SecureString"
  value     = each.value.result
  overwrite = true
}
