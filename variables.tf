
#export TF_VAR_google_client_id="112169100532-7o21oa7riuplqvds2ta4mhcabepr1465.apps.googleusercontent.com" => Setting a variable value from env during runtime
#unset TF_VAR_google_client_id => clearing an environment variable
#echo $TF_VAR_google_client_id => verifying the env variable
#export TF_VAR_google_client_secret="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"
#terraform state rm aws_cognito_user_group.CognitoRegisteredUsers



variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

variable "identity_providers" {
  description = "List of supported federated identity providers"
  type = list(string)

}

variable "url" {
  description = "Redirect / Callback URL"
  type = string
}

variable "env" {
  description = "Application Environment"
  type = string
}

locals {
  #email_address = "${var.first_name}.${var.last_name}@company.com" => Dynamic Local Variables
  domain = var.url
  app_name = "${var.env}-Isolutionz"
}