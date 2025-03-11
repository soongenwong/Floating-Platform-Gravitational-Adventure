import socket
import boto3
import json
import random
from decimal import Decimal
import threading
import time

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

def extract_values(cmsg_str):
    try:
        # Extract the first valid JSON part
        first_json_str = cmsg_str.split("\n")[0].split(": ", 1)[-1]  # Handles prefix like "Received from client X: "
        data = json.loads(first_json_str)  # Convert string to dictionary
        return data.get("id"), data.get("xpos"), data.get("ypos")
    except (json.JSONDecodeError, KeyError, IndexError):
        return None, None, None  # Return None values if parsing fails

print("We're in TCP server...")

# Configuration
server_port = 12000
spawn_count = 290
spawn_break_count = 70
spawn_moving_count = 30
spawn_range_x = (-120, 120)  # Example range, adjust as needed
spawn_range_y = (-4000, 0)    # Example range, adjust as needed

# Dictionary to store data for sending to Godot
platform_data = {
    "Platforms": [],
    "BreakingPlatforms": [],
    "MovingPlatforms": []
}

def make_():
    global spawn_count, spawn_break_count, spawn_moving_count, spawn_range_x, spawn_range_y
    # Generate platform data
    platform_positions = generate_positions(spawn_count, spawn_range_x, spawn_range_y)
    breaking_platform_positions = generate_special_positions(spawn_break_count, spawn_range_x, spawn_range_y)
    moving_platform_positions = generate_special_positions(spawn_moving_count, spawn_range_x, spawn_range_y)


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


make_()

# Start server - KEEP THESE LINES!
welcome_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
welcome_socket.bind(('0.0.0.0', server_port))
welcome_socket.listen(2)

# At the top of your script, add:

print('Server running on port', server_port)
print('Waiting for 2 clients to connect...')
# Accept first client
client1, addr1 = welcome_socket.accept()
print(f"Client 1 connected: {addr1}")

# Send platform data to first client with proper termination
json_data = json.dumps(platform_data)
client1.sendall((json_data + "\n").encode('utf-8'))  # Add newline delimiter
print("Sent platform data to client 1")

# Accept second client
client2, addr2 = welcome_socket.accept()
print(f"Client 2 connected: {addr2}")

# Send platform data to second client with proper termination
client2.sendall((json_data + "\n").encode('utf-8'))  # Add newline delimiter
print("Sent platform data to client 2")

# Function to handle a client
def handle_client(client_socket, client_num, other_client):
    try:
        while True:
            cmsg = client_socket.recv(1024)
            if not cmsg:
                break
            
            cmsg_str = cmsg.decode()
            jsoned = extract_values(cmsg_str)
            if len(jsoned) == 3 and jsoned[0] != None:
                print(f"Received from client {client_num}: {jsoned}")
                other_client.sendall((str(jsoned[0]) + " " + str(jsoned[1]) + " " + str(jsoned[2])).encode())

    except Exception as e:
        print(f"Error with client {client_num}: {e}")
    finally:
        client_socket.close()
        print(f"Client {client_num} disconnected")
print("start sleep")
time.sleep(3)
print("finished sleep")
# Start two threads to handle both clients
thread1 = threading.Thread(target=handle_client, args=(client1, 1, client2))
thread2 = threading.Thread(target=handle_client, args=(client2, 2, client1))

thread1.daemon = True
thread2.daemon = True

thread1.start()
thread2.start()

# Wait for both threads to finish (clients to disconnect)
thread1.join()
thread2.join()

print("Both clients disconnected. Server shutting down.")
