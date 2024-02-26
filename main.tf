#terraform fmt => Validate Syntax
#terraform plan => Validate Resource Declaration
#terraform destroy => Destroy Terraform Resources
#docker exec -it 569ffcc4bd9e /bin/bash => Ssh into container
#docker cp 569ffcc4bd9e:/usr/share/elasticsearch/config/certs /Users/mgas4756/Downloads/ca_certs/ => Copy files from docker container

resource "aws_cognito_user_pool" "pool" {
  name = "isolutionz_user_pool"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  alias_attributes    = ["email"]
  auto_verified_attributes = ["email"]
  #deletion_protection = "ACTIVE"

  device_configuration {
    challenge_required_on_new_device = true
  }

  mfa_configuration = "OPTIONAL"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"

  }

  username_configuration {
    case_sensitive = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Hey Isolutioner 😊. Your verification code is {####}"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
    invite_message_template {
      email_message = "Hey Isolutioner 😊. Your username is {username} and temporary password is {####}."
      email_subject = "Temporary Password"
      sms_message   = "Hey Isolutioner 😊. Your username is {username} and temporary password is {####}."
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    name                     = "email"
    mutable                  = true
    required                 = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    name                     = "username"
    mutable                  = true
    required                 = true
  }

  schema {
    name                     = "full_names"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "tenant_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "phone_number"
    developer_only_attribute = false
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = 10
      max_length = 16
    }
  }

}

#Cognito Client

resource "aws_cognito_user_pool_client" "isolutionzClient" {
  name = "isolutionz_client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret  = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]


  logout_urls   = [local.domain]
  callback_urls = [local.domain]

  supported_identity_providers = var.identity_providers
}

#User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "auth-isolutionz"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_identity_provider" "google_provider" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email openid profile"
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    "custom:full_names"  = "name"
  }
}

resource "aws_cognito_identity_provider" "microsoft_provider" {
  user_pool_id   = aws_cognito_user_pool.pool.id
  provider_name  = "Microsoft"
  provider_type  = "OIDC"

  provider_details = {
    client_id                   = data.aws_ssm_parameter.microsoft_client_id.value
    client_secret               = data.aws_ssm_parameter.microsoft_client_secret.value
    attributes_request_method   = "GET"
    oidc_issuer                 = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
    authorize_scopes            = "email profile openid"
  }

  attribute_mapping = {
    email      = "email"
    username   = "sub"
    full_names = "name"
  }
}


#Identity Pool
resource "aws_cognito_identity_pool" "isolutionz_auth" {
  identity_pool_name               = "isolutionz_identity_pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.isolutionzClient.id
    provider_name           = aws_cognito_identity_provider.google_provider.provider_name
    server_side_token_check = false
  }


  supported_login_providers = {
    "accounts.google.com" = var.google_client_id
  }

}

#Secrets Manager

# Create Secrets in Secrets Manager
resource "aws_secretsmanager_secret" "isolutionz_secrets" {
  name        = local.app_name
  description = "Secrets for Isolutionz"

  tags = {
    Name        = local.app_name
    Environment = var.env
  }
}


resource "aws_secretsmanager_secret_version" "isolutionz_secrets_version" {
  secret_id     = aws_secretsmanager_secret.isolutionz_secrets.id
  secret_string = jsonencode({
    userPoolID  = aws_cognito_user_pool.pool.id,
    clientId    = aws_cognito_user_pool_client.isolutionzClient.id,
    secretHash  = aws_cognito_user_pool_client.isolutionzClient.client_secret,
    tenantId    = "74b95e6b-d4f6-4704-8070-813c22897ab7",
  })
}

# Random password for secretHash
resource "random_password" "random_secret" {
  length  = 32
  special = true
}

//resource "aws_secretsmanager_secret_policy" "isolutionz_secrets_policy" {
//  secret_arn = aws_secretsmanager_secret.isolutionz_secrets.arn
//  policy     = data.aws_iam_policy_document.secrets_policy.json
//}


resource "aws_cognito_identity_pool_roles_attachment" "isolutionz_auth_idp_policy" {
  identity_pool_id = aws_cognito_identity_pool.isolutionz_auth.id

  roles = {
    authenticated   = aws_iam_role.auth_iam_role.arn
  }
}



resource "aws_iam_role" "auth_iam_role" {
  name = "auth_isolutionz_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.isolutionz_auth.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      },
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "s3_permissions"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::your-s3-bucket-name/*"
    }
  ]
}
EOF
  }

}



