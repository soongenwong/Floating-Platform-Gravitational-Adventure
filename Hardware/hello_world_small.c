#include "system.h"
#include "altera_up_avalon_accelerometer_spi.h"
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_timer.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "io.h"
#include <sys/alt_stdio.h>

#define OFFSET -32
#define PWM_PERIOD 16

#define SCALE_FACTOR 0.0078
#define JUMP_THRESHOLD 350  // 0.5g change for jump detection
#define BUFFER_SIZE 5  // Number of past samples to store
#define ABUFFER_SIZE 10  // Number of past samples to store
#define DASH_DETECTION_COUNT 3  // Number of consecutive readings needed for dash detection

alt_8 pwm = 0;
alt_u8 led;
int level;

// 7-segment display patterns for hexadecimal digits 0-F
// Segments: 6543210
//           gfedcba
const unsigned char seven_seg_digits_decode_gfedcba[16] = {
    0x3F, // 0: 0011 1111 - 0
    0x06, // 1: 0000 0110 - 1
    0x5B, // 2: 0101 1011 - 2
    0x4F, // 3: 0100 1111 - 3
    0x66, // 4: 0110 0110 - 4
    0x6D, // 5: 0110 1101 - 5
    0x7D, // 6: 0111 1101 - 6
    0x07, // 7: 0000 0111 - 7
    0x7F, // 8: 0111 1111 - 8
    0x6F, // 9: 0110 1111 - 9
    0x77, // A: 0111 0111 - A
    0x7C, // B: 0111 1100 - b
    0x39, // C: 0011 1001 - C
    0x5E, // D: 0101 1110 - d
    0x79, // E: 0111 1001 - E
    0x71  // F: 0111 0001 - F
};

// Function to display a hex digit on a specific HEX display
void display_hex(int display_number, int digit) {
    // Make sure digit is in the valid range (0-F)
    digit &= 0x0F;

    // Get the segment pattern for the digit
    unsigned char segments = seven_seg_digits_decode_gfedcba[digit];

    // Note: On many DE-series boards, the segments are active-low,
    // so we invert the pattern (~segments). If your board uses active-high,
    // remove the inversion.

    // Select the appropriate display based on display_number
    switch(display_number) {
        case 0:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX0_BASE, ~segments);
            break;
        case 1:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX1_BASE, ~segments);
            break;
        case 2:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX2_BASE, ~segments);
            break;
        case 3:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX3_BASE, ~segments);
            break;
        case 4:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX4_BASE, ~segments);
            break;
        case 5:
            IOWR_ALTERA_AVALON_PIO_DATA(HEX5_BASE, ~segments);
            break;
        default:
            // Invalid display number
            break;
    }
}

// Function to display a multi-digit hexadecimal number across multiple displays
// For example, display_hex_number(0xABCD, 4) will display ABCD on HEX3-HEX0
void display_hex_number(unsigned int number, int num_digits) {
    // Ensure num_digits is in valid range
    if (num_digits > 6) num_digits = 6;

    int num = 0x1234;

    // Display each digit
    for (int i = 0; i < num_digits; i++) {
        // Extract the least significant digit
        int digit = num & 0x0F;

        //alt_printf("Received: %c\n", c);

        // Display this digit on the appropriate display
        display_hex(i, digit);

        // Shift to the next digit
        num >>= 4;
    }
}

// Function to clear all displays
void clear_hex_displays() {
    // Write 0xFF to turn off all segments (assuming active-low)
    IOWR_ALTERA_AVALON_PIO_DATA(HEX0_BASE, 0xFF);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX1_BASE, 0xFF);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX2_BASE, 0xFF);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX3_BASE, 0xFF);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX4_BASE, 0xFF);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX5_BASE, 0xFF);
}

void led_write(alt_u8 led_pattern) {
    IOWR(LED_BASE, 0, led_pattern);
}

alt_u8 convert_read(alt_32 acc_read, int * level, alt_u8 * led) {
    acc_read += OFFSET;
    alt_u8 val = (acc_read >> 6) & 0x07;
    * led = (8 >> val) | (8 << (8 - val));
    * level = (acc_read >> 1) & 0x1f;
    //alt_printf("%x\n", *led);
    return *led;
}

void sys_timer_isr() {
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_BASE, 0);

/*    if (pwm < abs(level)) {

        if (level < 0) {
            led_write(led << 1);
        } else {
            led_write(led >> 1);
        }

    } else {
        led_write(led);
    }*/

    if (pwm > PWM_PERIOD) {
        pwm = 0;
    } else {
        pwm++;
    }

}

void timer_init(void * isr) {

    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_BASE, 0x0003);
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_BASE, 0);
    IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_BASE, 0x0900);
    IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_BASE, 0x0000);
    alt_irq_register(TIMER_IRQ, 0, isr);
    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_BASE, 0x0007);

}

int non_blocking_getchar() {
    int data = 20;
    if (data & 0x8000) {  // Check if data is available (MSB is set)
        return (char)(data & 0xFF);  // Return the received character
    }
    return data;  // No data available
}

int main() {

    alt_32 x_read, y_read, z_read;
    alt_u8 movement;
    alt_u8 logg;
    alt_u8 isJumping;
    int jump;
    int parse_hex;
    int result;

    char buffer[10];  // Buffer to store the received number
    int index = 0;
    char c;

    // Z-axis buffer for dashing detection
    float z_buffer[BUFFER_SIZE] = {0};  // Circular buffer to store past Z values
    int buffer_index = 0;

    // Variables for dash detection
    int dash_counter = 0;
    int is_dashing = 0;

    alt_up_accelerometer_spi_dev * acc_dev;
    acc_dev = alt_up_accelerometer_spi_open_dev("/dev/accelerometer_spi_0");
    if (acc_dev == NULL) { // if return 1, check if the spi ip name is "accelerometer_spi"
        return 1;
    }

    timer_init(sys_timer_isr);
    clear_hex_displays();
    int d = 0;
    int x = 0;
    int y = 0;

    while (1) {

    	//Write score to hex display
    	int cc = alt_getchar()-48;  // Receive one character at a time
    	int d = alt_getchar()-48;

    	if (((d==1)&&(cc==1))&&((10*d + cc)<y)){
    		x=0;
    	}

    	clear_hex_displays();
    	display_hex(0, d);
    	if (x==1){
    		display_hex(1, cc);
    	}
    	if(d==9){
    		x=1;
    	}
    	y = 10*d + cc;


        // Read X-axis data
        alt_up_accelerometer_spi_read_x_axis(acc_dev, &x_read);
        alt_up_accelerometer_spi_read_z_axis(acc_dev, &z_read);

        alt_u32 is_right_tilt = x_read & 0xF0000000;
        if (is_right_tilt == 0xF0000000){
        	alt_printf("direction: right\n");
        	x_read = ~x_read + 1;
        }
        else{
        	alt_printf("direction: left\n");
        }

        // 4. Determine direction based on filtered output
        alt_u32 mask = 0x000000F0;

                	parse_hex = x_read & mask;
                	result = parse_hex >> 4;
                	result = result & 0x0000000F;

                if (result > 0x9){
                	result += 0x6;
                }

                //result = result << 1;

                alt_printf(" speed: %x\n", result);

        float previous_z = z_buffer[(buffer_index + BUFFER_SIZE - 1) % BUFFER_SIZE];  // Get last stored Z value
        float dz = z_read - previous_z;  // Change in Z acceleration

        // Dash detection logic
        if (dz > JUMP_THRESHOLD) {
            // Increment the dash counter when threshold is exceeded
        	alt_printf(" dashing");
        }

        // Update buffer
        z_buffer[buffer_index] = z_read;
        buffer_index = (buffer_index + 1) % BUFFER_SIZE;

        // Check button for jump
        jump = ~IORD_ALTERA_AVALON_PIO_DATA(BUTTON_BASE);
        jump &= (0b0000000001);
        IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE, jump);

        if (jump == (0b1)) {
            alt_printf(" jumping");
        }

        alt_printf("\n");
        usleep(5000);
    }

    return 0;
}