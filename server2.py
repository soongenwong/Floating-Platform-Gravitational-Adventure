import socket
import boto3
from decimal import Decimal

def add_platform_data(table_name, platform_id, xpos, ypos, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    
    table = dynamodb.Table(table_name)
    
    response = table.put_item(
        Item={
            'platform_id': platform_id,
            'xpos': Decimal(str(xpos)),  # Convert to Decimal
            'ypos': Decimal(str(ypos))   # Convert to Decimal
        }
    )
    
    return response

print("We're in tcp server...")

# Select a server port
server_port = 12000
# Create a welcoming socket
welcome_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# Bind the server to the localhost at port server_port
welcome_socket.bind(('0.0.0.0', server_port))    

welcome_socket.listen(1)

# Ready message
print('Server running on port ', server_port)

# Now the main server loop
connection_socket, caddr = welcome_socket.accept()

# Initialize counters for each table
platform_id = 1
breaking_platform_id = 1
moving_platform_id = 1

# Start with the default table
current_table = "Platforms"

while True:
    # Receive data
    cmsg = connection_socket.recv(1024)
    cmsg = cmsg.decode('utf-8', errors='ignore')  # Ignore non-UTF-8 characters
    
    if cmsg:
        print("Received raw data:", cmsg)
        
        # Split the message by newlines
        lines = cmsg.strip().split('\n')
        print(f"Parsed {len(lines)} lines")
        
        try:
            for line in lines:
                # Clean the line by removing any non-printable characters
                line = ''.join(c for c in line if c.isprintable())
                
                if not line:
                    continue
                
                # Check if this line specifies a table name
                if line == "Platforms":
                    current_table = "Platforms"
                    print(f"Switching to table: {current_table}")
                    continue
                elif line == "BreakingPlatforms":
                    current_table = "BreakingPlatforms"
                    print(f"Switching to table: {current_table}")
                    continue
                elif line == "MovingPlatforms":
                    current_table = "MovingPlatforms"
                    print(f"Switching to table: {current_table}")
                    continue
                    
                
                # Otherwise, process as platform data
                parts = line.strip().split()
                if len(parts) >= 2:  # Make sure we have at least x and y values
                    xpos, ypos = parts[0], parts[1]
                    
                    # Use the appropriate ID based on the current table
                    if current_table == "Platforms":
                        platform_key = f"platform_{platform_id}"
                        platform_id += 1
                    elif current_table == "BreakingPlatforms":
                        platform_key = f"breaking_{breaking_platform_id}"
                        breaking_platform_id += 1
                    elif current_table == "MovingPlatforms":
                        platform_key = f"moving_{moving_platform_id}"
                        moving_platform_id += 1
                    
                    response = add_platform_data(current_table, platform_key, xpos, ypos)
                    print(f"Added {platform_key} to {current_table}: xpos={xpos}, ypos={ypos}")
                    
        except Exception as e:
            print(f"Error processing data: {str(e)}")
    
    # Echo back to client
    connection_socket.send("Data received".encode())
