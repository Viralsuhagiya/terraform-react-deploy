resource "aws_ecs_cluster" "react_app" {
  name = "${var.app_name}-${var.env}-ecr"
}

resource "aws_ecs_task_definition" "react_app" {
  family                   = "${var.app_name}-${var.env}-family"
  cpu                      = 256   
  memory                   = 512  
  container_definitions    = jsonencode([
    {
      name             = "${var.app_name}-${var.env}-family"
      image            = "${var.image}:latest"
      essential        = true
      portMappings     = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = var.loggroup
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${var.app_name}-${var.env}-stream"
        }
      }
      memory           = 512
      cpu              = 256
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.execution_role_arn
}

resource "aws_ecs_service" "react_app" {
  name            = "${var.app_name}-${var.env}-service"
  cluster         = aws_ecs_cluster.react_app.id
  task_definition = aws_ecs_task_definition.react_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${var.security_id}"]
    subnets = [
        var.subnet1,
        var.subnet2
    ]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${aws_ecs_task_definition.react_app.family}"
    container_port   = 3000 # Specifying the container port
  }

}