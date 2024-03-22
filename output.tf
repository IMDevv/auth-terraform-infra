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

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.isolutionzClient.id
  description = "User Pool Isolutionz Client ID"
}

output "cognito_identity_provider_cognito" {
  value = aws_cognito_user_pool.pool.endpoint
  description = "Cognito Identity Provider Endpoint"
}

output "cognito_identity_provider_google_name" {
  value = aws_cognito_identity_provider.google_provider.provider_name
  description = "Google Identity Provider Name"
}

output "cognito_user_pool_google_user_group" {
  value = aws_cognito_user_group.googleExternalUsers.name
  description = "Google Custome user Defined User Group"
}

output "user_pool_client_secret" {
  value = aws_cognito_user_pool_client.isolutionzClient.client_secret
  description = "User Pool Isolutionz Client Secret"
  sensitive = true
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.isolutionz_ecs_cluster.arn
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.isolutionz_ecs_service.id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.isolutionz_ecs_alb.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.isolutionz_ecs_task_definition.arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecsTaskExecutionRole.arn
}

output "ec2_ecs_role_profile_arn" {
  description = "EC2 Service Instance Profile Ec2-Ecs"
  value       = aws_iam_instance_profile.ec2_ecs_instance_profile.arn
}

output "aws_mesh_name" {
  description = "Mesh of isolutionz microservices namespace"
  value       = aws_appmesh_mesh.isolutionz_microservices_mesh.name
}

output "aws_cloudmap_auth_service_name" {
  description = "Auth service cloudmap name"
  value       = aws_service_discovery_service.cloud_map_auth_service.name
}

output "redis_ssm_configs" {
  description = "Redis SSM configuration"
  value       = local.redis_config_json
  sensitive = true
}