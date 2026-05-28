resource "aws_lb" "study_alb" {
  name               = "study-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.study_alb_sg.id
  ]

  subnets = [
    var.subnet_id_1,
    var.subnet_id_2
  ]
}

resource "aws_lb_target_group" "study_alb_tg" {
  name        = "study-alb-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.study_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.study_alb_tg.arn
        weight = 1
      }

      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}