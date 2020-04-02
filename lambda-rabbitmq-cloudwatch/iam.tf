data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "lambda_ecs" {
  name               = var.prefix
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Disable*",
      "cloudwatch:Enable*",
      "cloudwatch:Get*",
      "cloudwatch:Put*",
      "cloudwatch:Set*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]

    resources = [
      var.kms_arn,
    ]
  }
}

resource "aws_iam_role_policy" "lambda_ecs" {
  name   = var.prefix
  role   = aws_iam_role.lambda_ecs.id
  policy = data.aws_iam_policy_document.policy.json
}

