# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "sagemaker_notebook" {
    name = "fraud-detection-notebook"
    instance_type = "ml.t2.medium"
    role_arn = aws_iam_role.sagemaker_execution_role.arn
    subnet_id = aws_subnet.private_subnets[0].id
    security_groups = [aws_security_group.sagemaker_sg.id]

    tags = {
        Name = "fraud-detection-notebook"
    }
}


# Define the SageMaker model
resource "aws_sagemaker_model" "fraud_detection_model" {
  name                  = "fraud-detection-model"
  execution_role_arn    = aws_iam_role.sagemaker_execution_role.arn
  primary_container {
    image               = "764974769150.dkr.ecr.eu-west-2.amazonaws.com/sagemaker-xgboost:1.7-1"
    model_data_url      = "s3://fraud-detection-sagemaker-bucket-talha/train-data/model.tar.gz"
  }

  tags = {
    Name = "fraud-detection-model"
  }
}


# Deploy SageMaker Endpoint for Real-Time Fraud Detection
resource "aws_sagemaker_endpoint" "fraud_detection_endpoint" {
    name = "fraud-detection-endpoint"
    endpoint_config_name = aws_sagemaker_endpoint_configuration.fraud_detection_config.name
}

resource "aws_sagemaker_endpoint_configuration" "fraud_detection_config" {
    name = "fraud-detection"
    
    production_variants {
      variant_name = "AllTraffic"
      model_name = aws_sagemaker_model.fraud_detection_model.name
      initial_instance_count = 1
      instance_type = "ml.m5.large"
    }
}

