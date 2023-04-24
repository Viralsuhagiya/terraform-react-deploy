provider "aws" {
  region = "us-east-1"
}

# terraform {
#   required_providers {
#     docker = {
#       source = "kreuzwerker/docker"
#     }
#   }
# }

# provider "docker" {}

resource "aws_ecr_repository" "react_terrafrom_app" {
  name = "react_terrafrom_app"
}

resource "aws_ecs_cluster" "react_terraform_cluster" {
  name = "react_terraform_cluster"
}

# resource "docker_image" "my_image" {
#   name          = "${aws_ecr_repository.react_terrafrom_app.repository_url}:latest"
#   build  {
#     context    = "./../"
#     dockerfile = "./../Dockerfile"
#   }
# }

output "image_url" {
  value = "${aws_ecr_repository.react_terrafrom_app.repository_url}:latest"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecs_task_definition" "react_terraform_task_defination" {
  family                   = "react-terraform-task"
  cpu                      = 256   
  memory                   = 512  
  

  container_definitions    = jsonencode([
    {
      name      = "react-terraform-app"
      image     = "${aws_ecr_repository.react_terrafrom_app.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group" = "terraform-task-defination-logs"
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "terraform"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
      ]
    },
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_service" "my_service" {
  name            = "react-terraform-service"
  cluster         = aws_ecs_cluster.react_terraform_cluster.id
  task_definition = aws_ecs_task_definition.react_terraform_task_defination.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.my_security_group.id}"]
    subnets = [
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id,
    ]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.my_target_group.arn}"
    container_name   = "react-terraform-app"
    container_port   = 80
  }
}
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

output "load_balancer_url" {
  value = "${aws_lb.my_lb.dns_name}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "react terraform deploy vpc"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id,
    ]
  security_groups    = ["${aws_security_group.my_security_group.id}"]

  tags = {
    Name = "my_lb"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.my_vpc.id}"
  target_type = "ip"

  health_check {
    path = "/"
  }

  tags = {
    Name = "my_target_group"
  }
}


resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}


resource "aws_security_group" "my_security_group" {
  name_prefix = "my-security-group-"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}
