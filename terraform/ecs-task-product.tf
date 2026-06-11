resource "aws_ecs_task_definition" "product" {
  family                   = "${var.project_name}-product-tsk"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = "arn:aws:iam::286668306333:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::286668306333:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "product-service"
      image     = "286668306333.dkr.ecr.ap-south-1.amazonaws.com/product:${var.product_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
        }
      ]

      secrets = [
        { name = "JWT_SECRET", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:JWT_SECRET::" },
        { name = "DB_PORT", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_PORT::" },
        { name = "DB_NAME", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_NAME::" },
        { name = "DB_USER", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_USER::" },
        { name = "DB_PASSWORD", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:DB_PASSWORD::" },
        { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
        { name = "NODE_ENV", valueFrom = "arn:aws:secretsmanager:ap-south-1:286668306333:secret:/quickcart/backend/common-rL3fc5:NODE_ENV::" }
      ]

      environment = [
        { name = "AWS_REGION", value = "ap-south-1" },
        { name = "S3_BUCKET_NAME", value = "devops-project-frontend-rajesh" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-product"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}
