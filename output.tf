output "google_client_secret" {
  value = var.google_client_secret
  description = "Google Client Secret"
  sensitive = true
}

output "microsoft_client_id" {
  value = data.aws_ssm_parameter.microsoft_client_id.value
  description = "Microsoft Azure Client ID"
  sensitive = true
}

output "secrets_manager_arn_policy" {
  value = data.aws_iam_policy_document.secrets_policy
  description = "Secrets Manager Policy"
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
  description = "User Pool ID"
}