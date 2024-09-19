# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
    vpc_id = aws_vpc.main_vpc.id
    name = "ecs-sg"

    # Allow inbound SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound 
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "ecs-sg"
    }
}



# Security Group for ALB
resource "aws_security_group" "alb_sg" {
    name = "alb-security-group"
    vpc_id = aws_vpc.main_vpc.id

    # Inbound Rules (Allow HTTP and HTTPS from the internet)
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound Rules (Allow all outbound traffic)
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "alb-sg"
    }
}

# IAM Role for ECS Task Execution with X-Ray and CloudWatch
resource "aws_iam_role" "ecs_task_execution_role" {
    name = "ecs-task-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Principal = {
                service = "ecs-tasks.amazonaws.com"
            },
            Effect = "Allow",
            Sid = ""
        }]
    }) 
}

# Attach X-Ray and CloudWatch Policies to the Role
resource "aws_iam_role_policy_attachment" "xray_policy" {
    role = aws_iam_role.xray_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
} 

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
    role = aws_iam_role.ecs_task_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# IAM Role for X-Ray
resource "aws_iam_role" "xray_role" {
    name = "xray-task-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole",
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            },
            Effect = "Allow",
            Sid = ""
        }]
    })
}

# IAM Role for Sagemaker to access S3 bucket
resource "aws_iam_role" "sagemaker_execution_role" {
    name = "sagemaker-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "sagemaker.amazonaws.com"
            },
            Action = "sts:AssumeRole"

        }]

    })
}

# Attach policies for S3 and other resources
resource "aws_iam_role_policy_attachment" "sagemaker_s3_policy" {
    role = aws_iam_role.sagemaker_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_execution_role" {
    role = aws_iam_role.sagemaker_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Security Group for SageMaker
resource "aws_security_group" "sagemaker_sg" {
  name   = "sagemaker-security-group"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"] # Random trusted IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for Fargate to write to Kinesis
resource "aws_iam_role" "fargate_kinesis_role" {
    name = "fargate-kinesis-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

# Attach policy to allow writing to Kinesis
resource "aws_iam_role_policy_attachment" "kinesis_write_policy" {
    role = aws_iam_role.fargate_kinesis_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

# IAM Role for Kinesis Firehose to write to S3
resource "aws_iam_role" "firehose_delivery_role" {
    name = "firehose-delivery-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ecs-tasks.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

# Attach S3 access policy to Kinesis Firehose
resource "aws_iam_role_policy_attachment" "firehose_s3_access" {
    role = aws_iam_role.firehose_delivery_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}