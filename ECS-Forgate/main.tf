resource "aws_vpc" "NodeJs_VPC" {
    cidr_block           = var.vpc_cidr
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "nodejs"
    }
}

resource "aws_subnet" "public-subnet-1" {
    vpc_id                  = aws_vpc.NodeJs_VPC.id
    cidr_block              = var.public_sb1_cidr
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "public-subnet-1"
    }
}

resource "aws_subnet" "private-subnet-1" {
    vpc_id            = aws_vpc.NodeJs_VPC.id
    cidr_block        = var.private_sb1_cidr
    availability_zone = "us-east-1a"
    tags = {
        Name = "private-subnet-1"
    }
}

resource "aws_subnet" "public-subnet-2" {
    vpc_id                  = aws_vpc.NodeJs_VPC.id
    cidr_block              = var.public_sb2_cidr
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "public-subnet-2"
    }
}

resource "aws_subnet" "private-subnet-2" {
    vpc_id            = aws_vpc.NodeJs_VPC.id
    cidr_block        = var.private_sb2_cidr
    availability_zone = "us-east-1b"
    
    tags = {
        Name = "private-subnet-2"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.NodeJs_VPC.id
    
    tags = {
        Name = "iqw"
    }
} 

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.NodeJs_VPC.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    
    tags = {
        Name = "public-route-table"
    }
}

resource "aws_route_table_association" "rta_to_public1" {
    subnet_id      = aws_subnet.public-subnet-1.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "rta_to_public2" {
    subnet_id      = aws_subnet.public-subnet-2.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "eip" {
    vpc = true
    
    tags = {
        Name = "eip"
    }
}  

resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public-subnet-1.id
    
    tags = {
        Name = "nat-gw"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.NodeJs_VPC.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gw.id
    }

    tags = {
        Name = "private-route-table"
    }
}

resource "aws_route_table_association" "rta_to_private1" {
    subnet_id      = aws_subnet.private-subnet-1.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "rta_to_private2" {
    subnet_id      = aws_subnet.private-subnet-2.id
    route_table_id = aws_route_table.private_route_table.id
}

##########################################################################

# Create a security group for the Load Balancer and ECS service
resource "aws_security_group" "nodejs_sg" {
    name_prefix = "nodejs-security-group"
    vpc_id      = aws_vpc.NodeJs_VPC.id

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

############################################################################

# Application Load Balancer
resource "aws_lb" "nodejs_alb" {
    name               = "nodejs-alb"
    load_balancer_type = "application"
    security_groups    = [aws_security_group.nodejs_sg.id]
    subnets            = [aws_subnet.public-subnet-1.id,aws_subnet.public-subnet-2.id]
    ip_address_type    = "ipv4" 

    tags = {
        Name = "NodeJs-LB"
    }
}

# Target Group
resource "aws_lb_target_group" "nodejs_tg" {
    name        = "alb-tg"
    port        = 3000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.NodeJs_VPC.id
    target_type = "ip"
}

resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.nodejs_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.nodejs_tg.arn
    }
}

##################################################################################

# Create an ECR repository
resource "aws_ecr_repository" "nodejs" {
    name         = "nodejs"
    force_delete = true
}

# Create an ECS cluster
resource "aws_ecs_cluster" "nodejs-app-cluster" {
    name = "nodejs-app-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "nodejs-app-cluster-capacity_provider" {
    cluster_name       = aws_ecs_cluster.nodejs-app-cluster.name
    capacity_providers = ["FARGATE"]

    default_capacity_provider_strategy {
        base              = 1
        weight            = 100
        capacity_provider = "FARGATE"
    }
}

# Create a CloudWatch log group
resource "aws_cloudwatch_log_group" "nodejs_app" {
    name              = "/ecs/nodejs-app"
    retention_in_days = 7
}

#################################################################################

# Create an IAM role for ECS tasks
resource "aws_iam_role" "ecsTaskExecutionRole" {
    name               = "ecsTaskExecutionRole"
    assume_role_policy = jsonencode({
        Version        = "2012-10-17"
        
        Statement = [
        {
            Effect    = "Allow"
            Principal = {
                Service   = "ecs-tasks.amazonaws.com"
            }
            Action    = "sts:AssumeRole"
        }
        ]
    })

    managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
    ]
}

#####################################################################################

# Create an ECS task definition
resource "aws_ecs_task_definition" "nodejs-app-task" {
    family                   = "nodejs-app-task-definition"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = "1024"  # 1 vCPU
    memory                   = "3072"  # 3 GB
    task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
    execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn 

    container_definitions = jsonencode([
        {
        name         = "nodejs-app"
        image        = "${aws_ecr_repository.nodejs.repository_url}:latest"
        essential    = true
        portMappings = [
            {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
            }
        ]
        logConfiguration = {
            logDriver           = "awslogs"
            options             = {
                awslogs-group         = aws_cloudwatch_log_group.nodejs_app.name
                awslogs-region        = "us-east-1"
                awslogs-stream-prefix = "ecs"
            }
        }
        }
    ])
}

# Create an ECS service
resource "aws_ecs_service" "nodejs-app-service" {
    name            = "nodejs-app-service"
    cluster         = aws_ecs_cluster.nodejs-app-cluster.id
    task_definition = aws_ecs_task_definition.nodejs-app-task.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        subnets          = [aws_subnet.private-subnet-1.id,aws_subnet.private-subnet-2.id]
        security_groups  = [aws_security_group.nodejs_sg.id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.nodejs_tg.arn
        container_name   = "nodejs-app"
        container_port   = 3000
    }

    depends_on = [
        aws_ecs_task_definition.nodejs-app-task,
        aws_lb_listener.front_end
    ]
}