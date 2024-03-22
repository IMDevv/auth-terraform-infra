data "aws_ssm_parameter" "microsoft_client_secret" {
  name = var.azure_client_secret_ssm
  with_decryption = true
}

data "aws_ssm_parameter" "microsoft_client_id" {
  name = var.azure_client_ssm
  with_decryption = true
}

data "aws_ssm_parameter" "redis_config" {
  name = var.redis_config_ssm
  with_decryption = true
}


#Secrets Manager Access Policy for Admin Group
data "aws_iam_policy_document" "secrets_policy" {
  statement {
    sid    = "EnableAccessToSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::183599391281:root"]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.isolutionz_secrets.arn]
  }
}


data "aws_iam_policy_document" "isolutionz_ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "isolutionz_ecs_container_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "instance_assume_role_ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


data "aws_ami" "isolutions_ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}



