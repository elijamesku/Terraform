#defining provider and aws region(data center)
provider "aws" {
  region = "us-east-2"
}

#S3 bucket creation
resource "aws_s3_bucket" "terraform-state" {
  bucket = "ss33-bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "terraform-state"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform-state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

#adding versioning to S3
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform-state.id

  versioning_configuration {
    status = "Enabled"
  }

}

#default encryption at rest (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"

}

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

#port 80 access ingress + egress(inbound + outbound traffic)
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

#creating launch template for ec2s
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

  #tagging instances/volumes at launch to track(tag) which ec2 the instances(computers) and volumes(hard disks) are attached to
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

#creating aws autoscaling group with suze configs 
resource "aws_autoscaling_group" "web" {
  health_check_type   = "ELB"
  name                = "terraform-asg-example"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 10
  target_group_arns   = [aws_lb_target_group.asg.arn]
  vpc_zone_identifier = data.aws_subnets.default.ids

  #launch template with latest version
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

  #roll instances automatically when the LT changes meaning always have at least 90% running
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
    triggers = ["launch_template"]
  }

  #create a instance and ensure that it works before destroying the one that was duplicated
  lifecycle {
    create_before_destroy = true
  }
}

#load balancer so that you dont have to deploy a ip for each ec2 you want people to ingress to 
resource "aws_lb" "loadbalancer" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

}

#lb listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

variable "server_port" {
  description = "Port the app listens on"
  type        = number
  default     = 80

}

resource "aws_security_group" "alb" {
  name   = "terraform-example-alb"
  vpc_id = data.aws_vpc.default.id

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

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

output "alb_dns_name" {
  value       = aws_lb.loadbalancer.dns_name
  description = "The domain of the load balancer"

}