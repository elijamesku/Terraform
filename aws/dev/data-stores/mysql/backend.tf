terraform {
  backend "s3" {
    bucket  = "ss33-bucket"
    key     = "aws/dev/data-stores/mysql/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true

  }
}