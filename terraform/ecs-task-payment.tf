resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project_name}-payment-tsk"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = "arn:aws:iam::286668306333:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::286668306333:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name       = "payment-service"
      image      = "286668306333.dkr.ecr.ap-south-1.amazonaws.com/payment:${var.payment_image_tag}"
      essential  = true

      portMappings = [
        {
          containerPort = 5004
          hostPort      = 5004
        }
      ]

      secrets = [
        {
          name      = "JWT_SECRET"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:JWT_SECRET::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_PORT::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_NAME::"
        },
        {
          name      = "DB_USER"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_USER::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_PASSWORD::"
        },
        {
          name      = "DB_HOST"
          valueFrom = aws_ssm_parameter.db_host.arn
        },
        {
          name      = "ORDERS_SERVICE_URL"
          valueFrom = aws_ssm_parameter.order_service_url.arn
        },
        {
          name      = "NODE_ENV"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:NODE_ENV::"
        },
        {
          name      = "STRIPE_PUBLISHABLE_KEY"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:STRIPE_PUBLISHABLE_KEY::"
        },
        {
          name      = "STRIPE_SECRET_KEY"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:STRIPE_SECRET_KEY::"
        },
        {
          name      = "STRIPE_WEBHOOK_SECRET"
          valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:STRIPE_WEBHOOK_SECRET::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-payment"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}
