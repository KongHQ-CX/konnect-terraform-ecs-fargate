resource "aws_ecs_task_definition" "this" {
  family = "${var.runtime_group}-gateway"
  
  cpu    = 1024
  memory = 2048

  container_definitions = jsonencode([
    {
      name      = "proxy"
      image     = "${var.kong_image_repository}:${var.kong_image_tag}"
      cpu       = 0
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 8443
          hostPort      = 8443
        }
      ]

      secrets = [
        {
          name = "KONG_CLUSTER_CERTY"
          valueFrom = var.cluster_cert_secret_arn
        },
        {
          name = "KONG_CLUSTER_CERT_KEY"
          valueFrom = var.cluster_cert_key_secret_arn
        }
      ]

      environment = [
        {
          name = "KONG_CLUSTER_CONTROL_PLANE"
          value = "${var.control_plane_address}:443"
        },
        {
          name = "KONG_CLUSTER_TELEMETRY_ENDPOINT"
          value = "${var.telemetry_address}:443"
        },
        {
            name ="KONG_CLUSTER_TELEMETRY_SERVER_NAME"
            value = var.telemetry_address
        },
        {
            name ="KONG_KONNECT_MODE"
            value ="on"
        },
        {
            name ="KONG_PROXY_LISTEN"
            value ="0.0.0.0:8000,0.0.0.0:8443 http2 ssl"
        },
        {
            name ="KONG_CLUSTER_SERVER_NAME"
            value = var.control_plane_address
        },
        {
            name ="KONG_VITALS"
            value ="off"
        },
        {
          name = "KONG_DATABASE"
          value = "off"
        },
        {
          name = "KONG_ROLE"
          value = "data_plane"
        },
        {
          name = "KONG_CLUSTER_MTLS"
          value = "pki"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = local.log_prefix
          awslogs-region = var.region
          awslogs-stream-prefix = "kong-gateway"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.this.arn
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
}
