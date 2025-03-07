from flask import Flask, request, jsonify

app = Flask(__name__)

# Global variable to store the latest classification
latest_classification = "center + still"

@app.route('/data', methods=['PUT'])
def receive_data():
    global latest_classification
    data = request.get_json()
    if data and "classification" in data:
        latest_classification = data["classification"]
        print(f"Received data: {latest_classification}")
    return jsonify({"message": "Data received"}), 200

@app.route('/data', methods=['GET'])
def get_data():
    return jsonify({"classification": latest_classification})

if __name__ == "__main__":
    app.run(host='127.0.0.1', port=9000, debug=True)
