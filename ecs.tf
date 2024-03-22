resource "aws_kms_key" "isolutionz_ecs_logs_encryption_key" {
  description             = "Kms encryption key ecs logs"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "isolutionz_ecs_log_group" {
  name = "isolutionz_ecs_log_group"
}

resource "aws_ecs_cluster" "isolutionz_ecs_cluster" {
  name = "isolutionz_ecs_cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.isolutionz_ecs_logs_encryption_key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.isolutionz_ecs_log_group.name
      }
    }
  }
}


resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "isolution_ecs_capacity_provider"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }

  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_providers" {
 cluster_name = aws_ecs_cluster.isolutionz_ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
 
}

resource "aws_cloudwatch_log_group" "ecs_auth_service_log_group" {
  name              = "/ecs/${local.app_name}-auth-service"
  retention_in_days = 7
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_cloudwatch_log_group" "ecs_auth_service_mesh_proxy_log_group" {
  name              = "/ecs/${local.app_name}-auth-service-mesh-proxy"
  retention_in_days = 7
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

#Create the task defination
resource "aws_ecs_task_definition" "isolutionz_ecs_task_definition" {
 family             = "isolutionz_ecs_task"
 network_mode       = "awsvpc"
 task_role_arn =  aws_iam_role.ecsTaskExecutionRole.arn
 execution_role_arn = aws_iam_role.ecsContainerExecutionRole.arn
 cpu                = 256
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 container_definitions = jsonencode([
  {
      name      = "isolutionz_auth_container"
      image     = "public.ecr.aws/n6t5p2r4/isolutionz-auth-service:1.0.1"
      cpu       = 156
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        }
      ],
      # Configure logging
      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group"           = "${aws_cloudwatch_log_group.ecs_auth_service_log_group.name}"
          "awslogs-region"          = var.aws_region_name
        }
      }
    },
   {
    name      = "isolutionzAuthContainerProxy"
    image     = "840364872350.dkr.ecr.eu-west-1.amazonaws.com/aws-appmesh-envoy:v1.27.3.0-prod"
    cpu       = 100
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 15000  
        protocol      = "tcp"
      },
      {
        containerPort = 15001  
        protocol      = "tcp"
      }
    ],
      # Configure logging
      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group"           = "${aws_cloudwatch_log_group.ecs_auth_service_mesh_proxy_log_group.name}"
          "awslogs-region"          = "${var.aws_region_name}"
        }
      },
       environment = [
        {
          name  = "APPMESH_RESOURCE_ARN",
          value = "${aws_appmesh_virtual_gateway.isolutionz_microservices_mesh_gateway.arn}",
        }
      ],
  }
 ])
  proxy_configuration {
    type           = "APPMESH"
    container_name = "isolutionzAuthContainerProxy"
    properties = {
      AppPorts         = "4000"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

# Create IAM role for ECS task execution
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.isolutionz_ecs_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.ecs_execution_policy.arn, "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_iam_role" "ecsContainerExecutionRole" {
  name = "ecsContainerExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.isolutionz_ecs_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


resource "aws_iam_policy" "ecs_execution_policy" {
  name = "isolutionz_auth_ecs_task_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = [
          "cognito-identity:ListIdentityPools",
          "cognito-identity:ListIdentities",
          "cognito-identity:GetId",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
    ]
  })
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


resource "aws_cloudwatch_metric_alarm" "ecs_service_rollback_alarm" {
  alarm_name          = "ECSRollbackAlarm"
  alarm_description   = "Alarm for ECS service rollback"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1  
  period              = 60
  statistic           = "Sum"

  # ECS Service metric configuration
  namespace  = "AWS/ECS"
  metric_name = "ServiceDesiredCount"
  dimensions = {
    ServiceName = aws_ecs_service.isolutionz_ecs_service.name
    ClusterName = aws_ecs_service.isolutionz_ecs_service.cluster
  }

  # Actions to perform when the alarm state changes
  #actions_enabled       = true
  #alarm_actions         = [aws_autoscaling_policy.rollback_policy.arn]  # Replace with your rollback policy ARN
  #insufficient_data_actions = []
}



resource "aws_ecs_service" "isolutionz_ecs_service" {
 name            = "isolutions_ecs_service"
 cluster         = aws_ecs_cluster.isolutionz_ecs_cluster.id
 task_definition = aws_ecs_task_definition.isolutionz_ecs_task_definition.arn
 desired_count   = 2
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent = 200
 enable_ecs_managed_tags = true

 deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker  {
   enable = true
   rollback = true
  }

 network_configuration {
   subnets         = [aws_subnet.zonea.id, aws_subnet.zoneb.id]
   security_groups = [aws_security_group.service_security_group.id]
 }

 force_new_deployment = true

 ordered_placement_strategy {
  type = "binpack"
  field = "memory"
 }

 placement_constraints {
   type = "distinctInstance"
 }


 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "isolutionz_auth_container"
   container_port   = 4000
 }

 service_registries {
    registry_arn = aws_service_discovery_service.cloud_map_auth_service.arn
  }

  

 depends_on = [aws_autoscaling_group.ecs_asg]

 tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


# Define AWS Cloud Map Namespace
resource "aws_service_discovery_private_dns_namespace" "isolutions_cloud_map_namespace" {
  name = "${var.auth_service_cloudmap_domain}"
  vpc  = aws_vpc.isolutionz_vpc.id
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


# Define Cloud Map Service
resource "aws_service_discovery_service" "cloud_map_auth_service" {
  name              = "${var.auth_service_prefix}"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.isolutions_cloud_map_namespace.id
     dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_appmesh_mesh" "isolutionz_microservices_mesh" {
  name = "${var.auth_service_mesh_name}"
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_appmesh_virtual_gateway" "isolutionz_microservices_mesh_gateway" {
  name      = "${var.auth_service_prefix}-vg"
  mesh_name = aws_appmesh_mesh.isolutionz_microservices_mesh.id

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }

  tags = {
    environment="${var.env}"
    application="${local.app_name}"
  }
}

resource "aws_appmesh_gateway_route" "isolutionz_microservices_mesh_gateway_rt" {
  name                 = "${var.auth_service_prefix}-gt-rt"
  mesh_name            = aws_appmesh_mesh.isolutionz_microservices_mesh.id
  virtual_gateway_name = aws_appmesh_virtual_gateway.isolutionz_microservices_mesh_gateway.name

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.auth-service-vs.name
          }
        }
      }

      match {
        prefix = "/auth"
      }
    }
  }

  tags = {
    environment = "${var.env}"
    application = "${local.app_name}"
  }
}


resource "aws_appmesh_virtual_router" "auth-service-vr" {
  name      = "${var.auth_service_prefix}-vr"
  mesh_name = aws_appmesh_mesh.isolutionz_microservices_mesh.id

  spec {
    listener {
      port_mapping {
        port     = 4000
        protocol = "http"
      }
    }
  }
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_appmesh_route" "auth-service-vr-route" {
  name                = "${var.auth_service_prefix}-vr-route"
  mesh_name           = aws_appmesh_mesh.isolutionz_microservices_mesh.id
  virtual_router_name = aws_appmesh_virtual_router.auth-service-vr.name

  spec {
    http_route {
      match {
        prefix = "/"
      }

      retry_policy {
        http_retry_events = [
          "server-error",
        ]
        max_retries = 1

        per_retry_timeout {
          unit  = "s"
          value = 15
        }
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.auth_service_vn.name
          weight       = 100
        }
      }
    }
  }
 tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


resource "aws_appmesh_virtual_service" "auth-service-vs" {
  name      = "${var.auth_service_prefix}.${var.auth_service_cloudmap_domain}"
  mesh_name = aws_appmesh_mesh.isolutionz_microservices_mesh.id

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.auth-service-vr.name
      }
    }
  }

   depends_on = [aws_appmesh_virtual_router.auth-service-vr,aws_service_discovery_service.cloud_map_auth_service]

  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


resource "aws_appmesh_virtual_node" "auth_service_vn" {
  name      = "${var.auth_service_prefix}-vn"
  mesh_name = aws_appmesh_mesh.isolutionz_microservices_mesh.id

  spec {
    backend {
      virtual_service {
        virtual_service_name = "${var.auth_service_prefix}.${var.auth_service_cloudmap_domain}"
      }
    }

    listener {
      port_mapping {
        port     = 4000
        protocol = "http"
      }

       health_check {
        protocol            = "http"
        path                = "/docs/auth/isolutionz"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        service_name   = aws_service_discovery_service.cloud_map_auth_service.name
        namespace_name = aws_service_discovery_private_dns_namespace.isolutions_cloud_map_namespace.name
      }
    }
  }

  depends_on = [aws_service_discovery_service.cloud_map_auth_service]

  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }

}