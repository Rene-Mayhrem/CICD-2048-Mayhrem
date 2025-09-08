provider "aws" {
  region = "us-east-1"
}

#! ECR Repository 
resource "aws_ecr_repository" "2048-game" {
  name = "2048-game"
}

# ! ECS Cluster
resource "aws_ecs_cluster" "game_cluster" {
  name = "${var.app_name}-cluster"
}

# ! ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-07"
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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# !ECS Task defintion
resource "aws_ecs_task_definition" "game_task" {
  family = "${var.app_name}-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode({
    name = var.app_name
    image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}:latest"
    essential = true
    portMapping = [
        {
            containerPort = 3000
            hostPort = 3000
            protocol = "tcp"
        }
    ]
  })
}

# ! VPC + Networking
resource "aws_vpc" "game_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "game_subnet" {
  vpc_id = aws_vpc.game_vpc.id 
  cidr_block = "10.0.0.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_internet_gateway" "gane_igw" {
  vpc_id = aws_vpc.game_vpc.id
}

resource "aws_route_table" "game_rt" {
  vpc_id =aws_vpc.game_vpc.id
}

resource "aws_route" "game_internet_access" {
  route_table_id = aws_route_table.game_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gane_igw.id
}

resource "aws_route_table_association" "game_rta" {
  subnet_id = aws_subnet.game_subnet.id 
  route_table_id = aws_route_table.game_rt.id
}

# ! Security group
resource "aws_security_group" "game_sg" {
    vpc_id = aws_vpc.game_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = ["0.0.0.0/0"]
    }
}

# ! App Load Balancer
resource "aws_lb" "game_lb" {
  name = "${var.app_name}-alb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [aws_security_group.game_sg.id]
  subnets = [aws_subnet.game_subnet.id]
}

resource "aws_lb_target_group" "game_tg" {
  name = "${var.app_name}-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = aws_vpc.game_vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "game_listener" {
  load_balancer_arn = aws_lb.game_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.game_tg.arn
  }
}

# ! ECS Service
resource "aws_ecs_service" "game_service" {
  name = "${var.app_name}-service"
  cluster = aws_ecs_cluster.game_cluster.id
  task_definition = aws_ecs_task_definition.game_task.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = [aws_subnet.game_subnet.id]
    security_groups = [aws_security_group.game_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.game_tg.arn
    container_name = var.app_name
    container_port = 3000
  }

  depends_on = [ aws_lb_listener.game_listener ]
}