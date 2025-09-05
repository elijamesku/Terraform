data "terraform_remote_state" "db_mysql" {
  backend = "s3"
  config = {
    bucket = "ss33-bucket"
    key    = "aws/dev/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

locals {
  db_host       = data.terraform_remote_state.db_mysql.outputs.mysql_address
  db_port       = data.terraform_remote_state.db_mysql.outputs.mysql_port
  db_secret_arn = data.terraform_remote_state.db_mysql.outputs.db_secret_arn
}
