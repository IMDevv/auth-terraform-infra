
#export TF_VAR_google_client_id="112169100532-7o21oa7riuplqvds2ta4mhcabepr1465.apps.googleusercontent.com" => Setting a variable value from env during runtime
#unset TF_VAR_google_client_id => clearing an environment variable
#echo $TF_VAR_google_client_id => verifying the env variable
#export TF_VAR_google_client_secret="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"
#terraform state rm aws_cognito_user_group.CognitoRegisteredUsers


variable "azure_client_ssm" {
  description = "Azure Client ID SSM Path"
  type        = string
  default = "/azure/client_id"
}

variable "azure_client_secret_ssm" {
  description = "Azure Secret SSM Path"
  type        = string
  default = "/azure/client_secret"
}
variable "redis_config_ssm" {
  description = "Redis Config SSM Path"
  type        = string
  default = "/redis/cloud/configs"
}

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

variable "vpc_cidr" {
  description = "Isolutions VPC CIDR"
  type = string
  default = "10.0.0.0/16"
}

variable "auth_service_prefix" {
  description = "Auth Service Identifier"
  type = string
  default = "authService"
}

variable "auth_service_cloudmap_domain" {
  description = "Auth Service Cloudmap Domain"
  type = string
  default = "isolutionz.local"
}

variable "auth_service_mesh_name" {
  description = "Auth Service Aws Mesh Name"
  type = string
  default = "isolutionz_microservices_mesh"
}

variable "aws_region_name" {
  description = "AWS Region Name"
  type = string
  default = "eu-west-1"
}

variable "env" {
  description = "Application Environment"
  type = string
}

locals {
  #email_address = "${var.first_name}.${var.last_name}@company.com" => Dynamic Local Variables
  domain = var.url
  app_name = "${var.env}-Isolutionz"
  redis_config_json = jsondecode(data.aws_ssm_parameter.redis_config.value)
}