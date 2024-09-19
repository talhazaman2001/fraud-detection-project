# DynamoDB Table for Fraud Detection Metadata
resource "aws_dynamodb_table" "fraud_detection_table" {
    name = "fraud-detection-table"
    billing_mode = "PAY_PER_REQUEST" 
    hash_key = "transaction_id"
    range_key = "timestamp"

    attribute {
        name = "transaction_id"
        type = "S"
    }

    attribute {
      name = "timestamp"
      type = "N"
    }

    tags = {
        Name = "Fraud Detection Metadata Table"
    }
}