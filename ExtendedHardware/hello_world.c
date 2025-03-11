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
#define JUMP_THRESHOLD 200  // 0.5g change for jump detection
#define BUFFER_SIZE 5  // Number of past samples to store
#define DASH_DETECTION_COUNT 3  // Number of consecutive readings needed for dash detection

// FIR filter parameters for X-axis
#define X_FIR_ORDER 4  // 4-tap filter for X-axis smoothing
#define X_DIRECTION_RIGHT_THRESHOLD -10  // Threshold for right direction (ADJUSTED - SWITCHED DIRECTIONS)
#define X_DIRECTION_LEFT_THRESHOLD 10    // Threshold for left direction (ADJUSTED - SWITCHED DIRECTIONS)

alt_8 pwm = 0;
alt_u8 led;
int level;

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

int main() {

    alt_32 x_read, y_read, z_read;
    alt_u8 movement;
    alt_u8 logg;
    alt_u8 isJumping;
    int jump;
    int parse_hex;
    int result;

    // Z-axis buffer for dashing detection
    float z_buffer[BUFFER_SIZE] = {0};  // Circular buffer to store past Z values
    int buffer_index = 0;

    // Variables for dash detection
    int dash_counter = 0;
    int is_dashing = 0;

    // X-axis FIR filter implementation
    float x_fir_coeffs[X_FIR_ORDER] = {0.4, 0.3, 0.2, 0.1};  // Weighted toward recent readings
    alt_32 x_history[X_FIR_ORDER] = {0};  // Buffer to store x values for FIR filter
    alt_u32 filtered_x = 0;  // Filtered output
    //char* direction = "centre";  // Direction string to print
    //char* speed = "still";       // Speed string to print

    alt_up_accelerometer_spi_dev * acc_dev;
    acc_dev = alt_up_accelerometer_spi_open_dev("/dev/accelerometer_spi_0");
    if (acc_dev == NULL) { // if return 1, check if the spi ip name is "accelerometer_spi"
        return 1;
    }

    timer_init(sys_timer_isr);
    while (1) {
        // Read X-axis data
        alt_up_accelerometer_spi_read_x_axis(acc_dev, &x_read);

        alt_u32 is_right_tilt = x_read & 0xF0000000;
        if (is_right_tilt == 0xF0000000){
        	alt_printf("direction: right\n");
        	x_read = ~x_read + 1;
        }
        else{
        	alt_printf("direction: left\n");
        }

        // Apply FIR filter to X-axis data
        // 1. Shift values in history buffer
        for (int i = X_FIR_ORDER-1; i > 0; i--) {
            x_history[i] = x_history[i-1];
        }
        // 2. Add new sample
        x_history[0] = x_read;

        // 3. Apply FIR filter (compute weighted sum)
        filtered_x = 0;
        for (int i = 0; i < X_FIR_ORDER; i++) {
            filtered_x += x_history[i] * x_fir_coeffs[i];
        }

        //alt_printf(" filtered x : %x\n", filtered_x);

        // 4. Determine direction based on filtered output
        // Note: Directions have been inverted from previous implementation
        alt_u32 mask = 0x000000F0;

                //alt_u32 is_right_tilt = x_read & 0xF0000000;
                //alt_printf("right? %x\n", is_right_tilt);


                	parse_hex = filtered_x & mask;
                	result = parse_hex >> 4;
                	result = result & 0x0000000F;

                if (result > 0x9){
                	result += 0x6;
                }

                //result = result << 1;

                alt_printf(" speed: %x\n", result);

        // Process original movement data for LED pattern (if needed)
        //movement = convert_read(x_read, &level, &led);

        // Print direction and speed based on filtered values
        //alt_printf("direction: %s speed: %s", direction, speed);

        // Read Z-axis for dash detection
        alt_up_accelerometer_spi_read_z_axis(acc_dev, &z_read);

        float previous_z = z_buffer[(buffer_index + BUFFER_SIZE - 1) % BUFFER_SIZE];  // Get last stored Z value
        float dz = z_read - previous_z;  // Change in Z acceleration

        // Dash detection logic
        if (dz > JUMP_THRESHOLD) {
            // Increment the dash counter when threshold is exceeded
            dash_counter++;
            if (dash_counter >= DASH_DETECTION_COUNT) {
                is_dashing = 1;  // Set dashing flag if threshold exceeded for consecutive readings
            }
        } else {
            // Reset counter if threshold not exceeded
            dash_counter = 0;
            is_dashing = 0;
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

        // Print dashing if condition is met
        if (is_dashing) {
            alt_printf(" dashing");
        }

        alt_printf("\n");
        usleep(100);
    }

    return 0;
}
