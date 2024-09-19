# Load data for training - store in S3 and load it into the SageMaker enivronment
import sagemaker
import boto3
import pandas as pd

# Set up Sagemaker session and bucket
sagemaker_session = sagemaker.Session()
bucket = 'fraud-detection-sagemaker-bucket'

# Load training data from S3
s3 = boto3.client('s3')
obj = s3.get_object(Bucket = bucket, Key = 'train-data/mock_financial_transactions.csv')
df = pd.read_csv(obj['Body'])

# Preprocess data
df = df.dropna() # Removes row with missing values 
X = df.drop('label', axis = 1) # Features
y = df['label'] # Fraud or not Fraud

# Split the data for training and validation
from sklearn.model_selection import train_test_split
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size = 0.2, random_state = 42)

# Train the XGBoost model using SageMaker's built-in algorithm
import sagemaker
from sagemaker import get_execution_role
from sagemaker.inputs import TrainingInput

# Define the XGBoost estimator
xgboost_container = sagemaker.image_uris.retrieve("xgboost", sagemaker_session.boto_region_name, "1.5-1")
role = get_execution_role()

xgb = sagemaker.estimator.Estimator(
    xgboost_container,
    role,
    instance_count = 1,
    instace_type = "ml.m5.large",
    output_path = f"s3://fraud-detection-sagemaker-bucket-talha/output",
    sagemaker_session=sagemaker_session
)

# Set Hyperparameters
xgb.set_hyperparameters(
    objective = "binary:logistic",
    num_round = 100,
    max_depth = 5,
    eta = 0.2,
    subsample = 0.8
)

# Prepare the data for XGBoost
train_input = TrainingInput(s3_data=f"s3://fraud-detection-sagemaker-talha/train-data", content_type="csv")
validation_input = TrainingInput(s3_data=f"s3://fraud-detection-sagemaker-talha/validation-data", content_type="csv")

# Train the model
xgb.fit({"train": train_input, "validation": validation_input})

# Deploy the model 
xgb_predictor = xgb.deploy(
    initial_instance_count = 1,
    instance_type = "ml.m5.large"
)

# Make predictions on new data
import numpy as np

# Create a NumPy array from the visible data
import numpy as np

test_data = np.array([
    ["56f7416a-e7b5-459a-bb79-9e747a41e725", "2024-04-08 14:09:00.569031", "Ortiz-Jones", 21612.70, 19547.36, 0],
    ["07024860-5834-4569-9503-b4fe5257756a", "2024-06-07 02:43:48.820203", "Allen, Tyler and Harris", 13961.59, 90181.44, 0],
    ["2b46a431-e786-4189-a5a1-f2b960d801b2", "2024-08-23 07:48:46.763404", "Knight-Myers", 20066.51, 78872.68, 0],
    ["85b27923-ab8a-4715-a0a2-d95b6aa19bca", "2024-06-30 10:33:19.333299", "Bell, Rios and Chambers", 34093.21, 72040.27, 0],
    ["44a33590-1b2f-476f-8add-c11b986f3a30", "2024-04-27 18:48:18.147877", "Nicholson Ltd", 9288.13, 99668.66, 0]
])

predictions = xgb_predictor.predict(test_data)
print(predictions)

# Integrate SageMaker into transaction monitoring system
import boto3

client = boto3.client('runtime.sagemaker')

# Invoke SageMaker endpoint with transaction data
response = client.invoke_endpoint(
    EndpointName='fraud-detection-endpoint',
    Body=b'{"features": [0.1, 0.2, 0.3, ...]}',
    ContentType='application/json'
)

# Parse the response
result = response['Body'].read().decode('utf-8')
print(result)

