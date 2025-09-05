terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "app" {
  source = "./dev/app"
  # pass any variables the app module expects:
  # vpc_id = var.vpc_id
}

module "mysql" {
  source = "./dev/data-stores/mysql"
  # db_name = var.db_name
}
