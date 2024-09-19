# ECS Cluster 
resource "aws_ecs_cluster" "ecs_cluster" {
    name = "financial-transaction-cluster"
}

# ECS Task Definition wtih X-Ray, Kinesis, Aurora, DynamoDB and S3
resource "aws_ecs_task_definition" "ecs_task" {
    family = "financial-transaction-task"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_execution_role.arn
    memory = 512
    cpu = 256

  container_definitions = jsonencode([
    {
      name      = "fraud-detection",
      image     = "your-docker-image",
      essential = true,
      portMappings = [{
        containerPort = 8080,
        protocol      = "tcp"
      }]
      
      environment = [
        {
            name = "KINESIS_STREAM_NAME"
            value = aws_kinesis_stream.fraud_detection_stream.name
        },
        {
          name  = "AURORA_DB_ENDPOINT"
          value = aws_rds_cluster.aurora_cluster.endpoint
        },
        {
          name  = "DYNAMODB_TABLE_NAME"
          value = aws_dynamodb_table.fraud_detection_table.name
        },
        {
          name  = "S3_BUCKET_NAME"
          value = aws_s3_bucket.fargate_datalake.bucket
        },
        {
            name = "AWS_REGION"
            value = "eu-west-2"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/fraud-detection-logs",
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "xray-daemon",
      image     = "amazon/aws-xray-daemon",
      essential = true,
      portMappings = [{
        containerPort = 2000,
        protocol      = "udp"
      }],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/xray-daemon",
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },   
  ])
}

# Load Balancer for ECS
resource "aws_lb_target_group" "ecs_target_group" {
  name        = "ecs-target-group"
  port        = 80                
  protocol    = "HTTP"            
  vpc_id      = aws_vpc.main_vpc.id   
  target_type = "ip"              
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"  # Expected response codes for health checks
  }

  tags = {
    Name = "ECS Target Group"
  }
}


# ECS Service
resource "aws_ecs_service" "ecs_service" {
    name = "fraud-detection-service"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.ecs_task.arn
    desired_count = 2
    launch_type = "FARGATE"

    network_configuration {
      subnets = aws_subnet.private_subnets[*].id
      security_groups = [aws_security_group.ecs_sg.id]
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.ecs_target_group.arn
        container_name = "fraud-detection"
        container_port = 8080
    }
}

