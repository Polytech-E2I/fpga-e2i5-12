#include "cep_platform.h"

#include <stdint.h>

/*
 * definition of macros
 * ---------------------------------------------------------------------------
 */

#define RED      0xf800
#define GREEN    0x07e0
#define BLUE     0x001f
#define WHITE    0xffff

// Pointers to the peripherals base address
// Video Memory
#define DISPLAY_SCALE 1
#define DISPLAY_SCALED_WIDTH  (DISPLAY_WIDTH  / DISPLAY_SCALE)
#define DISPLAY_SCALED_HEIGHT (DISPLAY_HEIGHT / DISPLAY_SCALE)

volatile uint32_t *img = (volatile uint32_t *)VRAM_OFFSET;

/*
 * definition of functions
 * ---------------------------------------------------------------------------
 */

/* function to write a pixel in a (x,y) position of video framebuffer */
void write_pixel(int pixel, int x, int y)
{
   unsigned int i, j;

   for (i = 0; i < DISPLAY_SCALE; ++i) {
      for (j = 0; j < DISPLAY_SCALE; ++j) {
         const unsigned int real_y = y * DISPLAY_SCALE + i;
         const unsigned int real_x = x * DISPLAY_SCALE + j;
         if ((real_y * DISPLAY_WIDTH + real_x) >= (DISPLAY_WIDTH * DISPLAY_HEIGHT)) {
         } else {
            img[real_y * DISPLAY_WIDTH + real_x] = pixel;
         }
      }
   }
}

/* function to clear entire screen to the selected color */
void clear_screen(uint32_t color)
{
    for (int y = 0; y < DISPLAY_SCALED_HEIGHT; y++) {
        for (int x = 0; x < DISPLAY_SCALED_WIDTH; x++) {
            write_pixel(color, x, y);
        }
    }
}

/* Initialize the configurations of the game. */
void start(void)
{
}

/*
 * main program
 * ---------------------------------------------------------------------------
 */
void main(void)
{
    clear_screen(GREEN);
    for (int y = 0; y < DISPLAY_SCALED_HEIGHT; y++) {
        if ((y >= 20) && (y < 220)) {
            for (int x = 0; x < DISPLAY_SCALED_WIDTH; x++) {
                if ((x < 20) || (x >= 300))
                    continue;
                if ((x >=0) && (x < (DISPLAY_SCALED_WIDTH/3)))
                    write_pixel(BLUE , x, y);
                if ((x >= (DISPLAY_SCALED_WIDTH/3)) && (x < (DISPLAY_SCALED_WIDTH/3)*2))
                    write_pixel(WHITE, x, y);
                if ((x >= (DISPLAY_SCALED_WIDTH/3)*2) && (x < (DISPLAY_SCALED_WIDTH/3)*3))
                    write_pixel(RED  , x, y);
            }
        }
    }

    for (int y = 230; y < 240; y++) {
        for (int x = 0; x < 10; x++) {
            write_pixel(RED, x, y);
        }
    }

    for (int y = 230; y < 240; y++) {
        for (int x = 310; x < 320; x++) {
            write_pixel(RED, x, y);
        }
    }

    for (int y = 0; y < 10; y++) {
        for (int x = 0; x < 10; x++) {
            write_pixel(RED, x, y);
        }
    }

    for (int y = 0; y < 10; y++) {
        for (int x = 310; x < 320; x++) {
            write_pixel(RED, x, y);
        }
    }

    while(1);
}

