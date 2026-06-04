resource "aws_cloudwatch_log_group" "study_ecs_logs" {
  name              = "/ecs/${var.task_family}"
  retention_in_days = 0
}

resource "aws_ecs_cluster" "study_cluster" {
  name = var.cluster_name

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

resource "aws_ecs_task_definition" "study_node_task" {
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = "arn:aws:iam::799637010981:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::799637010981:role/ecs-s3-task-role"

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${aws_ecr_repository.study_node_app.repository_url}:latest"
      essential = true
      cpu               = 256
      memoryReservation = 512

      environmentFiles = []
      mountPoints      = []
      systemControls   = []
      ulimits          = []
      volumesFrom      = []

      portMappings = [
        {
          name        = "${var.container_name}-${var.app_port}-tcp"
          appProtocol = "http"
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "DB_HOST",    value = aws_db_instance.study_db.address },
        { name = "DB_NAME",    value = var.db_name  },
        { name = "DB_USER",    value = var.db_user },
        { name = "S3_BUCKET_NAME", value = var.s3_bucket_name }
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
          awslogs-group         = "/ecs/${var.task_family}"
          awslogs-region        = var.aws_region
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
  name            = var.service_name
  cluster         = aws_ecs_cluster.study_cluster.id
  task_definition = aws_ecs_task_definition.study_node_task.arn
  desired_count   = 1
  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

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
    container_name   = var.container_name
    container_port   = var.app_port
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

resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 2
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.study_cluster.name}/${aws_ecs_service.study_node_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "study-ecs-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}