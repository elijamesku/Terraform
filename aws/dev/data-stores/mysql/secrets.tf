# Region (use a variable to avoid deprecated data attr warnings)
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

# Current account & partition for a correct wildcard ARN
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# Match any Secrets Manager ARN for the stable name "dev/mysql" (suffix varies)
locals {
  db_secret_arn_pattern = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:dev/mysql-*"
}

# Policy document that allows read access to THAT secret
data "aws_iam_policy_document" "db_secret_read" {
  statement {
    sid    = "AllowReadDbSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [local.db_secret_arn_pattern]
  }
}

# The managed policy
resource "aws_iam_policy" "db_secret_read" {
  name   = "dev-app-read-db-secret"
  policy = data.aws_iam_policy_document.db_secret_read.json
}


