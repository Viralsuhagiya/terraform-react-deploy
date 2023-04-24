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

# resource "docker_image" "my_image" {
#   name          = "${aws_ecr_repository.react_terrafrom_app.repository_url}:latest"
#   build  {
#     context    = "./../"
#     dockerfile = "./../Dockerfile"
#   }
# }

resource "aws_ecr_repository" "react_terrafrom_app" {
  name = "react_terrafrom_app"
}

resource "aws_ecs_cluster" "react_terraform_cluster" {
  name = "react_terraform_cluster"
}

resource "aws_ecs_task_definition" "react_terraform_task_definition" {
  family                   = "react-terraform-task"
  cpu                      = 256   
  memory                   = 512  
  container_definitions    = jsonencode([
    {
      name             = "react-terraform-task"
      image            = "158211228743.dkr.ecr.us-east-1.amazonaws.com/react_terrafrom_app:latest"
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
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "terraform-stream"
        }
      }
      memory           = 512
      cpu              = 256
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/terraform"
}


resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "ecsService" {
  name            = "react-terraform-service-ld"
  cluster         = aws_ecs_cluster.react_terraform_cluster.id
  task_definition = aws_ecs_task_definition.react_terraform_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.service_security_group.id}"]
    subnets = [
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id,
    ]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name   = "${aws_ecs_task_definition.react_terraform_task_definition.family}"
    container_port   = 3000 # Specifying the container port
  }

}

resource "aws_security_group" "service_security_group" {
  name        = "react-app-demo"
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}



resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
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
  load_balancer_type = "application"
  subnets = [
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id,
    ]
  security_groups    = ["${aws_security_group.service_security_group.id}"]
  tags = {
    Name = "my_lb"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.my_vpc.id}"# Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}

output "load_balancer_url" {
  value = "${aws_lb.my_lb.dns_name}"
}

output "image_url" {
  value = "${aws_ecr_repository.react_terrafrom_app.repository_url}:latest"
}