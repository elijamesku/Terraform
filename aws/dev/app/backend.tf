terraform {
  backend "s3" {
    bucket       = "ss33-bucket"
    key          = "aws/dev/app/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
