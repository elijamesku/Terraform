variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

locals {
  azs = ["us-east-2a","us-east-2b"]

  public_cidrs = [cidrsubnet(var.vpc_cidr, 4, 0), cidrsubnet(var.vpc_cidr, 4, 1)]
  app_cidrs    = [cidrsubnet(var.vpc_cidr, 4, 2), cidrsubnet(var.vpc_cidr, 4, 3)]
  db_cidrs     = [cidrsubnet(var.vpc_cidr, 4, 4), cidrsubnet(var.vpc_cidr, 4, 5)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { 
    Name = "dev-network", Env = "dev" 
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { 
    Name = "dev-igw" 
  }
}

# Public subnets + RT
resource "aws_subnet" "public" {
  for_each                = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[index(local.azs, each.key)]
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = { 
    Name = "dev-public-${each.key}" 
    Tier = "public" 
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id 
  }
  tags  = { 
    Name = "dev-public" 
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# One NAT (cost-optimized; not AZ-HA)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { 
    Name = "dev-nat-eip" 
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[local.azs[0]].id   # deterministic
  tags          = { 
    Name = "dev-nat" 
  }
  depends_on    = [aws_internet_gateway.igw]
}

# Private app subnets (egress via NAT)
resource "aws_subnet" "app" {
  for_each                  = toset(local.azs)
  vpc_id                    = aws_vpc.this.id
  cidr_block                = local.app_cidrs[index(local.azs, each.key)]
  availability_zone         = each.key
  map_public_ip_on_launch   = false
  tags = { 
    Name = "dev-app-${each.key}" 
    Tier = "app" 
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.this.id
  route { 
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
  }
  tags  = { 
    Name = "dev-app" 
  }
}

resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}

# Private DB subnets (no internet route)
resource "aws_subnet" "db" {
  for_each                  = toset(local.azs)
  vpc_id                    = aws_vpc.this.id
  cidr_block                = local.db_cidrs[index(local.azs, each.key)]
  availability_zone         = each.key
  map_public_ip_on_launch   = false
  tags = { 
    Name = "dev-db-${each.key}"
    Tier = "db" 
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "dev-db"
  subnet_ids = [for s in aws_subnet.db : s.id]
  tags       = { 
    Name = "dev-db" 
  }
}
