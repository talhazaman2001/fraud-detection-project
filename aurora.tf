# Aurora MySQL Cluster
resource "aws_rds_cluster" "aurora_cluster" {
    cluster_identifier = "fraud-detection-cluster-talha"
    engine = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.05.2"
    master_username = "admin"
    master_password = "password"
    skip_final_snapshot = false 
    final_snapshot_identifier = "my-final-snapshot"
    backup_retention_period = 7
    preferred_backup_window = "07:00-09:00"
    database_name = "frauddetection"
    storage_encrypted = true
    apply_immediately = true

    # VPC subnet settings
    db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
    vpc_security_group_ids = [aws_security_group.aurora_sg.id]

    tags = {
        Name = "Aurora Fraud Detection Cluster"
    }
}

# Aurora MySQL Instance
resource "aws_rds_cluster" "aurora_instance" {
    cluster_identifier = aws_rds_cluster.aurora_cluster.id
    engine = aws_rds_cluster.aurora_cluster.engine
    engine_version = aws_rds_cluster.aurora_cluster.engine_version
    apply_immediately = true

    tags = {
        Name = "Aurora Fraud Detection Instance"
    }
}

# Aurora Subnet Group
resource "aws_db_subnet_group" "aurora_subnet_group" {
    name = "aurora-subnet-group"
    subnet_ids = aws_subnet.private_subnets[*].id

    tags = {
        Name = "Aurora Subnet Group"
    }
}

# Aurora Security Group
resource "aws_security_group" "aurora_sg" {
    name = "aurora-security-group"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [aws_vpc.main_vpc.cidr_block]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}