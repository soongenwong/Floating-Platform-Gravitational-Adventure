#!/usr/bin/env python3
import time
import sys
import intel_jtag_uart
import requests
import re

def classify_position(x_raw, y_raw, z_raw):
    try:
        x_val = int(x_raw, 16)
        y_val = int(y_raw, 16)
        z_val = int(z_raw, 16)

        if x_raw.startswith('ffffff') and y_raw.startswith('ffffff'):
            position = "right"
        elif x_val > 20 and not x_raw.startswith('ffffff') and y_raw.startswith('ffffff'):
            position = "left"
        else:
            position = "center"

        movement = "jump" if z_val > 0xFF else "still"

        return f"{position} + {movement}"
    except Exception as e:
        print(f"Error in classify_position: {e}")
        return "center + still"

# Try loading the JTAG UART
try:
    ju = intel_jtag_uart.intel_jtag_uart()
except Exception as e:
    print(f"JTAG UART error: {e}")
    sys.exit(0)

print("Sending data to local HTTP server at 127.0.0.1:9000...")

try:
    while True:
        # Read FPGA data
        fpga_out = ju.read()
        if len(fpga_out) > 3:
            try:
                data_str = fpga_out.decode('utf-8', errors='ignore')

                x_match = re.search(r'x raw data: ([^,]+)', data_str)
                y_match = re.search(r'y raw data: ([^,]+)', data_str)
                z_match = re.search(r'z raw data: ([^\s]+)', data_str)

                if x_match and y_match and z_match:
                    x_parts = x_match.group(1).strip()
                    y_parts = y_match.group(1).strip()
                    z_parts = z_match.group(1).strip()

                    classification = classify_position(x_parts, y_parts, z_parts)
                    print(f"Classification: {classification}")

                    # Send classification to local HTTP server via PUT request
                    try:
                        response = requests.put(
                            "http://127.0.0.1:9000/data",
                            json={"classification": classification}
                        )
                        print(f"Server response: {response.status_code} - {response.text}")
                    except requests.RequestException as e:
                        print(f"HTTP request error: {e}")

            except Exception as e:
                print(f"Data processing error: {e}")

        time.sleep(0.1)

except KeyboardInterrupt:
    print("Process stopped by user.")
except Exception as e:
    print(f"Unexpected error: {e}")
