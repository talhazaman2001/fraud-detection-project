from flask import Flask, request, jsonify
import logging

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)

# Set static fraud detection rules
def detect_fraud(transaction):
    amount = transaction.get('amount', 0)

    if amount > 10000:
        return True
    return False

# Define route for fraud detection
def detect():
    try:
        transaction = request.get_json()

        if detect_fraud(transaction):
            logging.info("Fraud detected in transaction: %s", transaction)
            return jsonify({"message": "Fraud detected", "transaction": transaction}), 200
        
        else:
            return jsonify({"message": "No fraud detected", "transaction": transaction}), 200
        
    except Exception as e:
        logging.error(f"Error processing transaction: {str(e)}")
        return jsonify({"error: str(e)"}), 400
    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)



    