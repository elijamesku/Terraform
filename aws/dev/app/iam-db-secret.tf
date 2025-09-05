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

# pass the role name of the app (EC2/ECS/Lambda) at apply time
variable "app_role_name" {
  description = "IAM role name used by the app"
  type        = string
}

resource "aws_iam_role_policy_attachment" "app_db_secret_read" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.db_secret_read.arn
}
