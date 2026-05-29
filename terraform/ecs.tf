resource "aws_cloudwatch_log_group" "study_ecs_logs" {
  name              = "/ecs/study-node-task"
  retention_in_days = 0
}

resource "aws_ecs_cluster" "study_cluster" {
  name = "study-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

resource "aws_ecs_task_definition" "study_node_task" {
  family                   = "study-node-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = "arn:aws:iam::799637010981:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::799637010981:role/ecs-s3-task-role"

  container_definitions = jsonencode([
    {
      name      = "study-node-app"
      image     = "${aws_ecr_repository.study_node_app.repository_url}:latest"
      essential = true
      cpu               = 512
      memoryReservation = 1024

      environmentFiles = []
      mountPoints      = []
      systemControls   = []
      ulimits          = []
      volumesFrom      = []

      portMappings = [
        {
          name        = "study-node-app-3000-tcp"
          appProtocol = "http"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "AWS_REGION", value = "ap-northeast-1" },
        { name = "DB_HOST",    value = "study-db-ecs.chyeu8ous5n5.ap-northeast-1.rds.amazonaws.com" },
        { name = "DB_NAME",    value = "study_db" },
        { name = "DB_USER",    value = "admin" }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_password.arn}:DB_PASSWORD::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/study-node-task"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "study_node_service" {
  name            = "study-node-task-service-r7cd8nq1"
  cluster         = aws_ecs_cluster.study_cluster.id
  task_definition = aws_ecs_task_definition.study_node_task.arn
  desired_count   = 1
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets = [
      var.subnet_id_1,
      var.subnet_id_2
    ]

    security_groups = [
      aws_security_group.study_ecs_sg.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.study_alb_tg.arn
    container_name   = "study-node-app"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.http
  ]

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_ecs_managed_tags = true
  availability_zone_rebalancing = "ENABLED"
}