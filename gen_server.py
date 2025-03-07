import socket
import boto3
import json
import random
from decimal import Decimal

# AWS DynamoDB setup
def add_platform_data(table_name, platform_id, xpos, ypos, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')  # Match your region
    
    table = dynamodb.Table(table_name)
    
    response = table.put_item(
        Item={
            'platform_id': str(platform_id),  # Ensure platform_id is a string
            'xpos': Decimal(str(xpos)),      # Convert to Decimal for DynamoDB
            'ypos': Decimal(str(ypos))       
        }
    )
    
    return response

# Function to generate platform positions
def generate_positions(count, range_x, range_y):
    positions = []
    for i in range(count):
        xpos = random.uniform(range_x[0], range_x[1])
        ypos = (range_y[0] / count) * i  # Mimicking Godot's logic
        positions.append([xpos, ypos])
    return positions

def generate_special_positions(count, range_x, range_y):
    positions = []
    for i in range(count):
        xpos = random.uniform(range_x[0], range_x[1])
        ypos = ((range_y[0] + 500) / count) * i - 500  # Adjusted for special platforms
        positions.append([xpos, ypos])
    return positions

print("We're in TCP server...")

# Configuration
server_port = 12000
spawn_count = 290
spawn_break_count = 70
spawn_moving_count = 20
spawn_range_x = (-150, 150)  # Example range, adjust as needed
spawn_range_y = (-6000, 0)    # Example range, adjust as needed

# Generate platform data
platform_positions = generate_positions(spawn_count, spawn_range_x, spawn_range_y)
breaking_platform_positions = generate_special_positions(spawn_break_count, spawn_range_x, spawn_range_y)
moving_platform_positions = generate_special_positions(spawn_moving_count, spawn_range_x, spawn_range_y)

# Dictionary to store data for sending to Godot
platform_data = {
    "Platforms": [],
    "BreakingPlatforms": [],
    "MovingPlatforms": []
}

# Add to DynamoDB
platform_id = 1
for xpos, ypos in platform_positions:
    key = f"platform_{platform_id}"
    add_platform_data("Platforms", key, xpos, ypos)
    platform_data["Platforms"].append([xpos, ypos])
    platform_id += 1

breaking_platform_id = 1
for xpos, ypos in breaking_platform_positions:
    key = f"breaking_{breaking_platform_id}"
    add_platform_data("BreakingPlatforms", key, xpos, ypos)
    platform_data["BreakingPlatforms"].append([xpos, ypos])
    breaking_platform_id += 1

moving_platform_id = 1
for xpos, ypos in moving_platform_positions:
    key = f"moving_{moving_platform_id}"
    add_platform_data("MovingPlatforms", key, xpos, ypos)
    platform_data["MovingPlatforms"].append([xpos, ypos])
    moving_platform_id += 1

# Start server
welcome_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
welcome_socket.bind(('0.0.0.0', server_port))
welcome_socket.listen(2)

print('Server running on port', server_port)

connection_socket, caddr = welcome_socket.accept()
while True:
    # print(f"Client connected: {caddr}")

    # Convert platform data to JSON and send to Godot
    json_data = json.dumps(platform_data)
    connection_socket.sendall(json_data.encode('utf-8'))
    # print("Data sent to client:", json_data)

    #notice recv and send instead of recvto and sendto
    cmsg = connection_socket.recv(1024)
    cmsg = cmsg.decode()
    print(f"Received from client: {cmsg}")
    connection_socket.send(cmsg.encode())
    # Close connection after sending data
    # connection_socket.close()