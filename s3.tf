# S3 Bucket as Data Lake for Fargate
resource "aws_s3_bucket" "fargate_datalake" {
    bucket = "fargate-datalake-bucket"

}

# Enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "fargate_datalake" {
     bucket = aws_s3_bucket.fargate_datalake.id

    rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
}

# Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "fargate_datalake_versioning" {
  bucket = aws_s3_bucket.fargate_datalake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rule for Data Lake
resource "aws_s3_bucket_lifecycle_configuration" "fargate_datalake_config" {
  bucket = aws_s3_bucket.fargate_datalake.id

  rule {
    id = "fargate-datalake-archiving"

    expiration {
      days = 365
    }

    filter {
      and {
        prefix = "fargate datalake/"

        tags = {
          archive  = "true"
          datalife = "long"
        }
      }
    }

    status = "Enabled"

    # Transition data to STANDARD_IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition data to GLACIER after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}



# S3 Bucket for Kinesis Data Firehose (intermediate storage)
resource "aws_s3_bucket" "kinesis_firehose_bucket" {
    bucket = "fraud-detection-firehose-bucket"
}

# Enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "kinesis_firehose_bucket" {
     bucket = aws_s3_bucket.kinesis_firehose_bucket.id

    rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
}



# S3 Bucket for Training Data and Model Artifacts
resource "aws_s3_bucket" "sagemaker_bucket" {
    bucket = "fraud-detection-sagemaker-bucket-talha"

}

# Enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sagemaker_bucket" {
     bucket = aws_s3_bucket.sagemaker_bucket.id

    rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
}

# Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "fraud_detection_sagemaker_versioning" {
  bucket = aws_s3_bucket.sagemaker_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rule for Training data and Artifacts 
resource "aws_s3_bucket_lifecycle_configuration" "fraud_detection_sagemaker_config" {
  bucket = aws_s3_bucket.sagemaker_bucket.id

  rule {
    id = "fraud-detection-sagemaker-archiving"

    expiration {
      days = 365
    }

    filter {
      and {
        prefix = "training-data-and-artifacts/"

        tags = {
          archive  = "true"
          datalife = "long"
        }
      }
    }

    status = "Enabled"

    # Transition data to STANDARD_IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition data to GLACIER after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Upload training code (sagemaker-train-deploy.py) to S3 Bucket
resource "aws_s3_object" "training_code" {
  bucket = aws_s3_bucket.sagemaker_bucket.bucket
  key = "train-data/sagemaker-train-deploy.py"
  source = "${path.module}/mock-financial-transactions.csv"
}