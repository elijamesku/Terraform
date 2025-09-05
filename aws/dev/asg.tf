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


