
resource "aws_lb" "react_app" {
  name               = "${var.app_name}-${var.env}-lb"
  load_balancer_type = "application"
  subnets = [
        var.subnet1,
        var.subnet2,
    ]
  security_groups    = ["${var.security_id}"]
  tags = {
    Name = "${var.app_name}-${var.env}-lb"
  }
}

resource "aws_lb_target_group" "react_app" {
  name        ="${var.app_name}-${var.env}-target-gp"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "react_app" {
  load_balancer_arn = aws_lb.react_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.react_app.arn
  }
}