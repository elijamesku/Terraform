# Trust policy: EC2 instances can assume this role
data "aws_iam_policy_document" "app_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # ECS: ecs-tasks.amazonaws.com ; Lambda: lambda.amazonaws.com
    }
    actions = ["sts:AssumeRole"]
  }
}

# The role your instances will use
resource "aws_iam_role" "app" {
  name               = "dev-app-role"
  assume_role_policy = data.aws_iam_policy_document.app_trust.json
  tags = { Env = "dev", ManagedBy = "terraform" }
}

# Instance profile for the Launch Template
resource "aws_iam_instance_profile" "app" {
  name = "dev-app-instance-profile"
  role = aws_iam_role.app.name
}
