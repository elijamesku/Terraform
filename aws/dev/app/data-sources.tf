#defining default vpc to use
data "aws_vpc" "default" {
  default = true
}

#defining subnets to use from default vpc above
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}




