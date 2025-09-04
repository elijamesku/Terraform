terraform {
  backend "s3" {
    bucket       = "ss33-bucket"
    key          = "state/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}