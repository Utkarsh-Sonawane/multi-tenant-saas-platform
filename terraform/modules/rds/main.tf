resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "rds_instance" {
  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "demodb"
  username = "admin"
  port     = "3306"
  password = "utkarsh123"

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