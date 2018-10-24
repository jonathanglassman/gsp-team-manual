data "aws_iam_policy_document" "broker-catalog" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::awsservicebroker/templates/*",
      "arn:aws:s3:::awsservicebroker",
    ]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.table_name}",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter/asb-*",
    ]
  }
}

data "aws_iam_policy_document" "broker" {
  statement {
    actions = [
      "ssm:PutParameter",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter/asb-*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::awsservicebroker/templates/*",
    ]
  }

  statement {
    actions = [
      "cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:CancelUpdateStack",
    ]

    resources = [
      "arn:aws:cloudformation:${var.region}:${var.account_id}:stack/aws-service-broker-*/*",
    ]
  }

  statement {
    actions = [
      "athena:*",
      "dynamodb:*",
      "kms:*",
      "elasticache:*",
      "elasticmapreduce:*",
      "kinesis:*",
      "rds:*",
      "redshift:*",
      "route53:*",
      "s3:*",
      "sns:*",
      "sns:*",
      "sqs:*",
      "ec2:*",
      "iam:*",
      "lambda:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "broker-catalog" {
  name   = "broker-catalog"
  policy = "${data.aws_iam_policy_document.broker-catalog.json}"
}

resource "aws_iam_policy" "broker" {
  name   = "broker"
  policy = "${data.aws_iam_policy_document.broker.json}"
}

resource "aws_iam_user" "broker" {
  name = "svcbroker"
}

resource "aws_iam_user_policy_attachment" "broker-catalog" {
  user       = "${aws_iam_user.broker.name}"
  policy_arn = "${aws_iam_policy.broker-catalog.arn}"
}

resource "aws_iam_user_policy_attachment" "broker" {
  user       = "${aws_iam_user.broker.name}"
  policy_arn = "${aws_iam_policy.broker.arn}"
}

resource "aws_iam_access_key" "broker" {
  user = "${aws_iam_user.broker.name}"
}

output "access_key_id" {
  value = "${aws_iam_access_key.broker.id}"
}

output "secret_key_id" {
  value = "${aws_iam_access_key.broker.secret}"
}
