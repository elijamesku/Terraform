provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "web" {
  name        = "Terraform-EC2-1-instance"
  description = "Allow HTTP from anywhere"
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
}

resource "aws_instance" "example" {
  ami                         = "ami-0fb653ca2d3203ac1"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              set -euxo pipefail
              mkdir -p /opt/web
              echo "Hello welcome to the web server" > /opt/web/index.html
              cd /opt/web
              nohup python3 -m http.server 80 > /var/log/web.log 2>&1 &
              EOF
  tags = {
    Name = "Terraform-EC2-1"
  }
}