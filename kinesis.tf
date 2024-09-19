# Kinesis Data Stream to process data from Fargate
resource "aws_kinesis_stream" "fraud_detection_stream" {
    name = "fraud-detection-stream"
    shard_count = 40  # for high throughput of global bank

    retention_period = 24 # Data retention in hours

    tags = {
        Name = "fraud-detection-stream"
    }
}

# Kinesis Firehose Delivery Stream to S3
resource "aws_kinesis_firehose_delivery_stream" "fraud_detection_firehose" {
    name = "fraud-detection-firehose-talha"
    destination = "extended_s3"

    extended_s3_configuration {
        role_arn  = aws_iam_role.firehose_delivery_role.arn
        bucket_arn = aws_s3_bucket.kinesis_firehose_bucket.arn
        
        buffering_size = 5
        buffering_interval = 300
        compression_format = "GZIP" # compress data to save storage

        cloudwatch_logging_options {
          enabled = true
          log_group_name = "/aws/kinesisfirehose/fraud-detection"
          log_stream_name = "S3Delivery"
        }
    }
    tags = {
        Name = "fraud-detection-firehose"
    }
}
