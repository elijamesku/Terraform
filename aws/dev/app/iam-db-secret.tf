# assumes remote-db.tf sets:
#   local.db_secret_arn = data.terraform_remote_state.db_mysql.outputs.db_secret_arn

# 1) Trust policy: EC2 instances can assume this role
data "aws_iam_policy_document" "app_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] # ECS: "ecs-tasks.amazonaws.com" ; Lambda: "lambda.amazonaws.com"
    }
    actions = ["sts:AssumeRole"]
  }
}

# 2) The role & instance profile the ASG/instances will use
resource "aws_iam_role" "app" {
  name               = "dev-app-role"
  assume_role_policy = data.aws_iam_policy_document.app_trust.json
  tags               = { Env = "dev", ManagedBy = "terraform" }
}

resource "aws_iam_instance_profile" "app" {
  name = "dev-app-instance-profile"
  role = aws_iam_role.app.name
}

# 3) Policy that allows reading the DB secret
data "aws_iam_policy_document" "db_secret_read" {
  statement {
    sid    = "AllowReadDbSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [local.db_secret_arn]
  }
}

resource "aws_iam_policy" "db_secret_read" {
  name   = "dev-app-read-db-secret"
  policy = data.aws_iam_policy_document.db_secret_read.json
}

# 4) Attach the policy to the role
resource "aws_iam_role_policy_attachment" "app_db_secret_read" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.db_secret_read.arn
}
