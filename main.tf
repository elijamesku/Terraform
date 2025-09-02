provider "aws" {
  region = "us-east-2"
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#port 80 access ingress + egress
resource "aws_security_group" "web" {
  name        = "terraform-web-sg"
  description = "Allow HTTP from anywhere"
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
}

resource "aws_launch_template" "web" {
  name_prefix            = "web-"
  image_id               = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -euxo pipefail
              mkdir -p /opt/web
              echo "Hello welcome to the web server(from ASG)" > /opt/web/index.html
              cd /opt/web
              nohup python3 -m http.server 80 > /var/log/web.log 2>&1 &
              EOF
  )
  #tag instances/volumes at launch
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terraform-asg-example"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "terraform-asg-example"
    }
  }

  update_default_version = true
}

resource "aws_autoscaling_group" "web" {
  name                = "terraform-asg-example"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 10
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  #asg level tag 
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }

  #roll instances automatically when the LT changes 
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
    triggers = ["launch_template"]
  }

  lifecycle {
    create_before_destroy = true
  }
}