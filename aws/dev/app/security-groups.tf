# port 80 access for your instances (only from the ALB)
resource "aws_security_group" "web" {
  # name        = "terraform-web-sg"
  name_prefix = "dev-web-" # <= unique name
  description = "Allow HTTP from ALB only"
  vpc_id      = data.aws_vpc.default.id

  # Best practice: only ALB -> web, not the whole internet
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # <= ALB SG source
    # (older provider versions use 'source_security_group_id' instead)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dev-web" }
}

# ALB security group (internet -> ALB:80)
resource "aws_security_group" "alb" {
  # name   = "terraform-example-alb"
  name_prefix = "dev-alb-" # <= unique name
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dev-alb" }
}
