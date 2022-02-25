#include "brick.h"
#include "cep_platform.h"
#include "colors.h"

#include <stdint.h>

#ifdef ENV_QEMU
#include <string.h>
#include <stdio.h>
#endif

// Original resolution for old vga screens : 320*240

/*
 * definition of bitmap for each line in the pattern
 * ---------------------------------------------------------------------------
 */
uint32_t sprite_bar[BAR_C]     = {0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff};
uint32_t sprite_ball[BALL_C]   = {0x6,   0xf,    0xf,     0x6};
uint32_t sprite_brick[BRICK_C] = {0xffff, 0xffff, 0xffff, 0xffff};

uint32_t levels[N_LEVEL][WALL_C] = {
    { 0x8001, 0x4002, 0x2004, 0x1008, 0x0810, 0x0420, 0x0240, 0x0180 },
    { 0x0180, 0x0240, 0x0420, 0x0810, 0x0810, 0x0420, 0x0240, 0x0180 },
    { 0x0100, 0x0280, 0x0540, 0x0aa0, 0x0540, 0x0280, 0x0100, 0x0000 }
};


/*
 * definition of macros
 * ---------------------------------------------------------------------------
 */

#define N_OBJECTS 7             /* displayed objects (aliens, laser, spaceship) */

#define DISPLAY_SCALE  1
#define DW_UNSCALED   (DISPLAY_WIDTH  / DISPLAY_SCALE)
#define DH_UNSCALED   (DISPLAY_HEIGHT / DISPLAY_SCALE)

/*
 * definition of global variables
 * ---------------------------------------------------------------------------
 */

/* sprite objects */
object_t object[2] = {
   {BAR_L, BAR_C, (DW_UNSCALED - BAR_L) / 2, DH_UNSCALED - PATTERN_SIZE,
    0, 0, -1, -1, GREEN, sprite_bar},                                                                                                                                                                 /* blue bar */
   {BALL_L, BALL_C, (DW_UNSCALED - BALL_L) / 2, DH_UNSCALED - PATTERN_SIZE - BALL_C,
    0, 0, -1, -1, WHITE, sprite_ball},                                                                                                                                                                  /* balle */
};

brick_t Group[MAX_BRICK + 1];    /* tableau to storage a group of bricks */
uint32_t n_bric;                /* number of bircks existing */
uint32_t flip, level;           /* to remark if the ball has been shot and the level */

/* pointers to the peripherals base address */
volatile uint32_t *img = (volatile uint32_t *) VRAM_OFFSET;                                                                                                                                             /* Memory Video */

/*
 * main program
 * ---------------------------------------------------------------------------
 */

void main(void)
{
   /* declaration of local variables */
   uint32_t i, dx, dy;
   uint32_t push_state, led_state;

   object_t *bar, *ball;

   bar = &object[0];
   ball = &object[1];
   for (i = 0; i < MAX_BRICK; i++)
      Group[i].exist = 0;

   /* initialization stage */
   push_state = 0;              /* no button pressed at beginning */
   led_state = 0;               /* initial value displayed on leds */
   level = 0;                   /* start with the first level */
   flip = 0;                    /* the ball stays on the bar at the beginning */
   initialize();

   /* display stage */
   while (1) {

      /* build the wall */
      build(ball, bar);

      /* move the bar */
      move_bar(bar);

      /* move the ball */
      move_ball(ball);
      if (!flip)
         ball_on_bar(ball, bar);
      else
         bar_catch(ball, bar);

      /* display the bar and the ball */
      display_sprite(bar);
      display_sprite(ball);

      push_state = push_button_get();
      if (push_state & 0x01)
         /* bar to right */
         bar->dx = MOVE_1;
      if (push_state & 0x02)
         /* bar to left */
         bar->dx = -MOVE_1;
      if (push_state & 0x04) {
         /* flip the ball */
         if (!flip) {
            flip = 1;
            ball->dx = (ball->x > DW_UNSCALED / 2) ? MOVE_1 : -MOVE_1;
            ball->dy = -MOVE_2;
         }
      }

      /* manage leds' state */
      led_set(led_state);
      led_state++;
      timer_set_and_wait(TIMER_FREQ, 4);
   }
}

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
         //printf("real_x : %ld\n", real_x);
         //printf("real_y : %ld\n", real_y);
         img[real_y * DISPLAY_WIDTH + real_x] = pixel;
      }
   }
}

void *memset_32b(volatile uint32_t *dest, uint32_t c, uint32_t n)
{
   volatile uint32_t *p = dest;
   while (n-- > 0) {
      *(volatile uint32_t *) dest++ = c;
   }
   return (void *) p;
}

/* function to clear entire screen to the selected color */
void clear_screen(uint32_t color)
{
   memset_32b(img, color, DISPLAY_WIDTH * DISPLAY_HEIGHT);
}

/* function to initialize all objects */
void initialize()
{
   n_bric = 0;
   clear_screen(BLACK);         /* black screen */
}

/* function to display the pixels of a pattern line */
void display_pattern_line(uint32_t m, int x, int y, uint32_t color, uint32_t size_l)
{
   int i;

   for (i = 0; i < size_l; i++) {
      int new_color = ((m & 1) == 1) ? color : 0;
      m = m >> 1;
      write_pixel(new_color, x + i, y);
   }
}

/* function to display an object considering the last background */
void display_pattern(uint32_t *pattern, int x, int y, uint32_t color, uint32_t size_l, uint32_t size_c)
{
   uint32_t i;

   for (i = 0; i < size_c; i++)
      display_pattern_line(pattern[i], x, y + i, color, size_l);
}

/* function to display an object (spaceship, laser or alien) */
void display_sprite(object_t *object)
{
   uint32_t dx, dy;

   if ((object->ax == -1) && (object->ay == -1)) {
      for (dx = 0; dx < object->size_c; dx++) {
         for (dy = 0; dy < object->size_l; dy++) {
            object->bg[dx][dy] = BLACK;
         }
      }
   }

   if ((object->ax > -1 && object->ay > -1) && (object->x != object->ax || object->y != object->ay)) {
      for (dx = 0; dx < object->size_c; dx++) {
         for (dy = 0; dy < object->size_l; dy++) {
            write_pixel(object->bg[dx][dy], object->ax + dy, object->ay + dx);
         }
      }
   }

   object->ax = object->x;
   object->ay = object->y;

   display_pattern(object->pattern, object->x, object->y, object->color, object->size_l, object->size_c);
}

/* display bricks */
void display_brick(brick_t *brick)
{
   display_pattern(sprite_brick, brick->x, brick->y, brick->color, BRICK_L, BRICK_C);
}

/* destroy bricks */
void destroy_brick(brick_t *brick)
{
   uint32_t dx, dy;

   for (dx = 0; dx < BRICK_L; dx++)
      for (dy = 0; dy < BRICK_C; dy++)
         write_pixel(BLACK, brick->x + dx, brick->y + dy);

   brick->exist = 0;
   if (n_bric > 0)
      n_bric--;
   else
      n_bric = 0;
}

/* the situation when the ball smash the bricks */
void break_up(object_t *ball, brick_t *brick)
{
   int diff_x = ball->x - brick->x;
   int diff_y = ball->y - brick->y;

   if (brick->exist && (diff_x >= -BALL_L) && (diff_x <= BRICK_L)) {
      if ((diff_y >= -BALL_C) && (diff_y <= BRICK_C)) {
         ball->dy = -ball->dy;
         ball->dx = -ball->dx;
         destroy_brick(brick);
      }
   }
}

/* build the wall formed by the bricks */
void build_wall(uint32_t *canvas)
{
   uint32_t dx, dy;
   uint32_t selc_c = 0;
   for (dy = 0; dy < WALL_C; dy++)
      for (dx = 0; dx < WALL_L; dx++)
         if ((canvas[dy] >> dx & 1) && (n_bric < MAX_BRICK)) {
            n_bric++;
            Group[n_bric].x = (DW_UNSCALED - MAX_BRICK * BRICK_L) / 2 + dx * BRICK_L;
            Group[n_bric].y = (DH_UNSCALED / 8) + dy * BRICK_C;
            if (selc_c >= N_COLOR)
               selc_c -= (N_COLOR - 1);
            else
               selc_c++;
            switch (selc_c) {
            case 1:
               Group[n_bric].color = RED;
               break;
            case 2:
               Group[n_bric].color = YELLOW;
               break;
            case 3:
               Group[n_bric].color = CYAN;
               break;
            case 4:
               Group[n_bric].color = MAGENTA;
               break;
            }
            Group[n_bric].exist = 1;
         }
}

/* put the bar and the ball to the initial position */
void put_bar_ball(object_t *ball, object_t *bar)
{
   bar->x = (DW_UNSCALED - BAR_L) / 2;
   bar->y = DH_UNSCALED - PATTERN_SIZE;
   bar->dx = bar->dy = 0;
   ball_on_bar(ball, bar);
   flip = 0;
}

/* build the wall of each level */
void build(object_t *ball, object_t *bar)
{
   uint32_t i;
   /* rebuild the wall */
   if (!n_bric) {
      /* put the ball and the bar to the initiate place */
      put_bar_ball(ball, bar);
      if (level < N_LEVEL)
         build_wall(levels[level++]);
      else {
         level = 0;
         build_wall(levels[level]);
      }
   }

   /* display the wall */
   for (i = MAX_BRICK; i > 0; i--)
      if (Group[i].exist)
         display_brick(&Group[i]);

   /* detect if the bricks has been broken */
   for (i = MAX_BRICK; i > 0; i--)
      break_up(ball, &Group[i]);
}

/* move the bar according to the key clicked */
void move_bar(object_t *bar)
{
   /* move the bar according to the key clicked */
   bar->x += bar->dx;
   bar->y += bar->dy;
   if (bar->x < 0)
      bar->x = 0;
   if (bar->x > DW_UNSCALED - BAR_L)
      bar->x = DW_UNSCALED - BAR_L;

   /* the bar stays if none of the key has been clicked */
   bar->dx = 0;
   bar->dy = 0;
}

/* move the ball */
void move_ball(object_t *ball)
{
   /* flip the ball when the space has been clicked */
   ball->x += ball->dx;
   ball->y += ball->dy;
   if (ball->x > DW_UNSCALED - BALL_L) {
      ball->x = DW_UNSCALED - BALL_L;
      ball->dx = -MOVE_1;
   }
   if (ball->x < 0) {
      ball->x = 0;
      ball->dx = MOVE_1;
   }
   if (ball->y < 0) {
      ball->y = 0;
      ball->dy = MOVE_1;
   }

   /* when the ball drops out of the bottom of the window, replacing it to the bar */
   if (ball->y > DH_UNSCALED - BALL_C)
      flip = 0;
}

/* justify if the bar has caught the ball */
void bar_catch(object_t *ball, object_t *bar)
{
   /* when the ball hits the bar, the ball rebounds to different directions */
   if ((bar->y - ball->y) <= BALL_C && (bar->y - ball->y) > 0) {
      int d = ball->x - bar->x;
      if ((d >= 0) && (d <= BAR_L)) {
         ball->dy = -MOVE_1;
         if (d < BALL_L)
            ball->dx = -MOVE_2;
         else if (d > (BAR_L - BALL_L))
            ball->dx = MOVE_2;
      }
   }
}

/* the ball stays on the bar */
void ball_on_bar(object_t *ball, object_t *bar)
{
   /* when the ball haven't been yet flipped, it stays always on the bar */
   ball->dx = 0;
   ball->dy = 0;
   ball->x = bar->x + (BAR_L - BALL_L) / 2;
   ball->y = bar->y - BALL_C;
}
