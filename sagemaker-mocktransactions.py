# Mock Financial Transactions
import pandas as pd
import numpy as np
from faker import Faker
import random

# Initialise Faker to generate fake data
fake = Faker()

np.random.seed(42)

# Number of mock transactions
num_transactions = 1000

#Lists to store generated data
transaction_ids = []
timestamps = []
merchant_names = []
transaction_amounts = []
account_balances = []
is_fraud = []

# Function to generate mock transactions
for _ in range(num_transactions):
    transaction_ids.append(fake.uuid4())
    timestamps.append(fake.date_time_this_year())
    merchant_names.append(fake.company())
    transaction_amounts.append(round(random.uniform(10, 50000), 2)) # random transactions between 10 and 50000'
    account_balances.append(round(random.uniform(1000, 100000), 2)) # random account balances
    is_fraud.append(random.choices([0,1], weights = [95, 5])[0]) #5% chance of fraud

# Create a DataFrame with the generated data
transactions_df = pd.DataFrame({
    'transaction_id': transaction_ids,
    'timestamp': timestamps,
    "merchant_name": merchant_names,
    'transaction_amount': transaction_amounts,
    'account_balance': account_balances,
    'is_fraud': is_fraud
})

# Save data to a CSV file
transactions_df.to_csv('mock_financial_transactions.csv', index = False)

# Display the first few rows 
print(transactions_df.head())

