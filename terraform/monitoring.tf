resource "aws_cloudwatch_log_group" "study_ecs_logs" {
  name              = "/ecs/${var.task_family}"
  retention_in_days = 3
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "study-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.study_cluster.name
    ServiceName = aws_ecs_service.study_node_service.name
  }

  alarm_actions = [
    aws_sns_topic.alarm_topic.arn
  ]

  alarm_description  = "ECS CPU > 80%"
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "study-alb-target-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    LoadBalancer = aws_lb.study_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.study_alb_tg.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alarm_topic.arn
  ]

  alarm_description  = "ALB target 5XX count > 0"
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "study-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2

  metric_name = "TargetResponseTime"
  namespace   = "AWS/ApplicationELB"

  period    = 60
  statistic = "Average"

  threshold = 1

  dimensions = {
    LoadBalancer = aws_lb.study_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.study_alb_tg.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alarm_topic.arn
  ]

  alarm_description  = "ALB response time > 1 second"
  treat_missing_data = "notBreaching"
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

resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "study-ecs-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}