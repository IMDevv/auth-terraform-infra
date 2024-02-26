data "aws_ssm_parameter" "microsoft_client_secret" {
  name = "/azure/client_secret"
  with_decryption = true
}

data "aws_ssm_parameter" "microsoft_client_id" {
  name = "/azure/client_id"
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



