resource "aws_cloudwatch_dashboard" "study_dashboard" {
  dashboard_name = "study-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title = "ECS CPU Utilization"

          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", aws_ecs_cluster.study_cluster.name,
              "ServiceName", aws_ecs_service.study_node_service.name
            ]
          ]

          stat   = "Average"
          period = 300
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title = "ECS Memory Utilization"

          metrics = [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName", aws_ecs_cluster.study_cluster.name,
              "ServiceName", aws_ecs_service.study_node_service.name
            ]
          ]

          stat   = "Average"
          period = 300
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title = "ALB Response Time"

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer", aws_lb.study_alb.arn_suffix,
              "TargetGroup", aws_lb_target_group.study_alb_tg.arn_suffix
            ]
          ]

          stat   = "Average"
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title = "ALB Target 5XX"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer", aws_lb.study_alb.arn_suffix,
              "TargetGroup", aws_lb_target_group.study_alb_tg.arn_suffix
            ]
          ]

          stat   = "Sum"
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title = "ALB Healthy Host Count"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer", aws_lb.study_alb.arn_suffix,
              "TargetGroup", aws_lb_target_group.study_alb_tg.arn_suffix
            ]
          ]

          stat   = "Minimum"
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title = "ALB Request Count"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer", aws_lb.study_alb.arn_suffix,
              "TargetGroup", aws_lb_target_group.study_alb_tg.arn_suffix
            ]
          ]

          stat   = "Sum"
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          title = "ECS Live Task Count"

          metrics = [
            [
              "AWS/ECS",
              "LiveTaskCount",
              "ClusterName", aws_ecs_cluster.study_cluster.name,
              "ServiceName", aws_ecs_service.study_node_service.name
            ]
          ]

          stat   = "Average"
          period = 60
          region = var.aws_region
        }
      }
    ]
  })
}

