resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+{}:,.?"

}

resource "aws_secretsmanager_secret" "db" {
  name = "dev/mysql"
  tags = {
    Env       = "dev"
    ManagedBy = "terraform"
    Component = "data-stores"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })

}