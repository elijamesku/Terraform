# iam-db-secret.tf  (app stack)

# Who am I / where am I?
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Build an ARN pattern that works in any partition, without deprecated fields
locals {
  # arn:<partition>:secretsmanager:<region>:<account>:secret:dev/mysql-*
  db_secret_arn_pattern = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:dev/mysql-*"
}

# IAM policy: allow reading the dev/mysql secret (any suffix)
data "aws_iam_policy_document" "db_secret_read" {
  statement {
    sid     = "AllowReadDbSecret"
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [local.db_secret_arn_pattern]
  }
}

resource "aws_iam_policy" "db_secret_read" {
  name        = "dev-app-read-db-secret"
  description = "Allow app to read dev/mysql secret from AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.db_secret_read.json
}

# Attach to the app role defined in iam-role.tf
resource "aws_iam_role_policy_attachment" "app_db_secret_read" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.db_secret_read.arn
}
