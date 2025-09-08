/* one shared random suffix for this stack - terraform generating a stable suffix 
to be stored in state so it does not change between applies unless it is destroyed
*/
resource "random_pet" "suffix" {
  length = 2
}

# Application Load Balancer(layer 7)- distributes traffic to different ec2s 
resource "aws_lb" "loadbalancer" {
  name               = "dev-alb-${random_pet.suffix.id}" 
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

  # optional
  # idle_timeout = 60
  # enable_deletion_protection = false
  tags = {
    Name = "dev-alb-${random_pet.suffix.id}"
  }
}

# Target group for the ASG/instances
resource "aws_lb_target_group" "asg" {
  name     = "dev-asg-${random_pet.suffix.id}" 
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

  tags = {
    Name = "dev-asg-${random_pet.suffix.id}"
  }
}

# HTTP listener (80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
/*
# Listener rule (match all paths)
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/*"]    # match everything
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
*/