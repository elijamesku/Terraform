data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "mysql_dev" {
  name        = "dev-mysql-public"
  description = "Allow MySQL from allowed CIDR (dev)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "dev-mysql-public"
    Env       = "dev"
    ManagedBy = "terraform"
  }

}

resource "aws_db_instance" "mysql" {
  identifier_prefix = "dev-mysql"
  engine            = "mysql"
  engine_version    = "8.0.36"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.mysql_dev.id]

  skip_final_snapshot        = true
  deletion_protection        = false
  backup_retention_period    = 0
  auto_minor_version_upgrade = true
  port                       = 3306
  copy_tags_to_snapshot      = true

  tags = {
    Name      = "dev-mysql"
    Env       = "dev"
    ManagedBy = "terraform"
    Component = "data-stores"
  }
}
