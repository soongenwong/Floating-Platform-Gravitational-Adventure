import sys
import intel_jtag_uart
import socket
import re
import time
import select

# Try loading the JTAG UART
try:
    ju = intel_jtag_uart.intel_jtag_uart()
except Exception as e:
    print(f"JTAG UART error: {e}")
    sys.exit(0)

# Set up UDP socket for bidirectional communication
udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_address = ('127.0.0.1', 9000)  # Server address for sending data
client_address = ('0.0.0.0', 9001)    # Listen on all interfaces, different port for receiving
udp_socket.bind(client_address)        # Bind to receive messages
udp_socket.setblocking(False)          # Make socket non-blocking

print(f"Sending data to Godot via UDP at {server_address[0]}:{server_address[1]}...")
print(f"Listening for messages from Godot on port {client_address[1]}...")

def parse_new_format(data_str):
    try:
        # Extract direction
        direction_match = re.search(r'direction:\s*(left|right)', data_str)
        direction = direction_match.group(1) if direction_match else "centre"
        
        # Extract speed as an integer
        speed_match = re.search(r'speed:\s*(\d+)', data_str)
        speed = int(speed_match.group(1)) if speed_match else 0  # Default to 0 if not found
        
        # Detect dashing and jumping
        dashing = "dashing" if "dashing" in data_str else "nope"
        jumping = "jumping" if "jumping" in data_str else "hellnah"
        
        # Format output string
        classification = f"{direction} + {speed} + {dashing} + {jumping}"
        return classification

    except Exception as e:
        print(f"Error in parse_new_format: {e}")
        return "centre + 0 + nope + hellnah"

def process_godot_message(message):
    """Process messages received from Godot and send to FPGA if needed"""
    try:
        print(f"Received from Godot: {message}")
        
        # Example: Send command to FPGA if needed
        # Format will depend on what your FPGA code expects
        if message.startswith("FPGA:"):
            command = message[5:]  # Extract the actual command
            print(f"Sending to FPGA: {command}")
            ju.write(command + "\n")  # Send to FPGA with newline
            
        # Add more message handling logic as needed
            
    except Exception as e:
        print(f"Error processing Godot message: {e}")

try:
    while True:
        # Check for incoming messages from Godot (non-blocking)
        try:
            # Use select.select() which is available on all platforms
            readable, _, _ = select.select([udp_socket], [], [], 0.01)  # 10ms timeout
            
            if udp_socket in readable:
                data, addr = udp_socket.recvfrom(1024)
                message = data.decode('utf-8')
                process_godot_message(message)
        except (socket.error, select.error) as e:
            # Handle socket errors gracefully
            if not isinstance(e, BlockingIOError):  # Ignore expected blocking errors
                print(f"Socket error: {e}")
        except Exception as e:
            print(f"Error receiving UDP data: {e}")
        
        # Read FPGA data
        fpga_out = ju.read()
        if len(fpga_out) > 3:
            try:
                data_str = fpga_out.decode('utf-8', errors='ignore').strip()
                
                # Use the new parsing function
                classification = parse_new_format(data_str)
                print(f"Classification: {classification}")

                # Send classification directly via UDP
                try:
                    udp_socket.sendto(classification.encode(), server_address)
                except Exception as e:
                    print(f"UDP sending error: {e}")

            except Exception as e:
                print(f"Data processing error: {e}")

        time.sleep(0.05)  # Slightly faster polling for better responsiveness

        ju.write(b'8')

except KeyboardInterrupt:
    print("Process stopped by user.")
except Exception as e:
    print(f"Unexpected error: {e}")
finally:
    udp_socket.close()