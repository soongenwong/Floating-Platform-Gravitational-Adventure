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
#define JUMP_THRESHOLD 20  // 0.5g change for jump detection
#define BUFFER_SIZE 5  // Number of past samples to store


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

    float z_buffer[BUFFER_SIZE] = {0};  // Circular buffer to store past Z values
    int buffer_index = 0;
    alt_up_accelerometer_spi_dev * acc_dev;
    acc_dev = alt_up_accelerometer_spi_open_dev("/dev/accelerometer_spi_0");
    if (acc_dev == NULL) { // if return 1, check if the spi ip name is "accelerometer_spi"
        return 1;
    }

    timer_init(sys_timer_isr);
    while (1) {
    	//led_write(led << 1);
        alt_up_accelerometer_spi_read_x_axis(acc_dev, & x_read);
        alt_printf("x data: %x\n", x_read);
        movement = x_read; //convert_read(x_read, & level, & led);

        /*if (x_read > 0x30){
        	alt_printf("left");
        }
        else if (x_read < 0xFFFFFF00){
            alt_printf("centre");
        }
        else{
            alt_printf("right");
        }*/

        movement = convert_read(x_read, & level, & led);

                alt_printf("direction: ");

                if (movement < 10){
                	alt_printf("left");
                	if (movement == 8){
                		alt_printf(" speed: still");
                	}
                	else if (movement == 4){
                		alt_printf(" speed: medium");
                	}
                	else if (movement == 2){
                		alt_printf(" speed: fast");
                	}
                	else if (movement == 1){
                		alt_printf(" speed: none");
                	}
                }
                else if (movement > 20){
                	alt_printf("right");
                	if (movement == 0x20){
                	   alt_printf(" speed: still");
                    }
                	else if (movement == 0x40){
                	   alt_printf(" speed: medium");
                	}
                	else if (movement == 0x80){
                	   alt_printf(" speed: fast");
                	}
                	else if (movement == 0x80){
                	   alt_printf(" speed: none");
                	}
                }
                else{
                	alt_printf("centre");
                	alt_printf(" speed: still");
                }

        //alt_printf("direction: ");

        //alt_printf(x_read);

        //alt_printf("%x", movement);

        alt_up_accelerometer_spi_read_z_axis(acc_dev, & z_read);
        //alt_printf("z data: %x\n", z_read);

        float previous_z = z_buffer[(buffer_index + BUFFER_SIZE - 1) % BUFFER_SIZE];  // Get last stored Z value
        float dz = z_read - previous_z;  // Change in Z acceleration

        if (dz > JUMP_THRESHOLD) {
            alt_printf(" dashing");
        }

        // Update buffer
        z_buffer[buffer_index] = z_read;
        buffer_index = (buffer_index + 1) % BUFFER_SIZE;

		//Gets the data from the pb, recall that a 0 means the button is pressed
		jump = ~IORD_ALTERA_AVALON_PIO_DATA(BUTTON_BASE);
		//Mask the bits so the leftmost LEDs are off (we only care about LED3-0)
		jump &= (0b0000000001);
		//Send the data to the LED
		IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE,jump);

		if (jump == (0b0000000001)) {
		     alt_printf(" jumping");
		}

		alt_printf("\n");
        usleep(10000);
    }

    return 0;
}
