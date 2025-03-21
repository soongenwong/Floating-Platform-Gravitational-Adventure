#joe mama's udp:
import sys
import intel_jtag_uart
import socket
import re
import time

# Try loading the JTAG UART
try:
    ju = intel_jtag_uart.intel_jtag_uart()
except Exception as e:
    print(f"JTAG UART error: {e}")
    sys.exit(0)

# Set up UDP socket
udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_address = ('127.0.0.1', 9000)  # Same port as before for simplicity

print("Sending data to Godot via UDP at 127.0.0.1:9000...")

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

try:
    while True:
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
                    print(f"Sent via UDP: {classification}")
                except Exception as e:
                    print(f"UDP sending error: {e}")

            except Exception as e:
                print(f"Data processing error: {e}")

        #time.sleep(0.1)

except KeyboardInterrupt:
    print("Process stopped by user.")
except Exception as e:
    print(f"Unexpected error: {e}")
finally:
    udp_socket.close()