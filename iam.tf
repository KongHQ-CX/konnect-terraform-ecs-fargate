resource "aws_iam_role" "this" {
  name = "${var.runtime_group}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "extra-permissions"
    policy = data.aws_iam_policy_document.extra_permissions.json
  }
}

data "aws_iam_policy_document" "extra_permissions" {
  statement {
    actions   = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.cluster_cert_secret_arn != null ? var.cluster_cert_secret_arn : aws_secretsmanager_secret_version.cluster_cert[0].arn,
      var.cluster_cert_key_secret_arn != null ? var.cluster_cert_key_secret_arn : aws_secretsmanager_secret_version.cluster_key[0].arn,
    ]
  }

  statement {
    actions   = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetAuthorizationToken",
      "ecr:ListImages"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:*:repository/${var.kong_image_repository}/*"
    ]  
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
