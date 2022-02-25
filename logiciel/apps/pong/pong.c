#include "cep_platform.h"
#include "colors.h"
#include "pong.h"

#include <stdint.h>
#include <stdlib.h>

/* 
 * definition of macros
 * ---------------------------------------------------------------------------
 */

// #SCALING
#define DISPLAY_SCALE  1

/* pointers to the peripherals base address */
/* Video Memory */
volatile uint32_t *img = (volatile uint32_t *) VRAM_OFFSET;
/*
 * definition of global variables
 * ---------------------------------------------------------------------------
 */

/* Racket of player A */
uint32_t sprite_racket_A[C_RACKET] = {
   0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf
};

/* Racket of player B */
uint32_t sprite_racket_B[C_RACKET] = {
   0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf, 0xf
};

/* Ping pong ball */
uint32_t sprite_ball[C_BALL] = { 0x6, 0xf, 0xf, 0x6 };

uint32_t sprite_number[MAX_DIGIT][N_SIZE_COLONNE] = {
   /* Number zero */
   {0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x00, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x00},
   /* Number one */
   {0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00},
   /* Number two */
   {0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7e, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7e, 0x00},
   /* Number three */
   {0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7e, 0x00},
   /* Number four */
   {0x00, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00},
   /* Number five */
   {0x7e, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7e, 0x00},
   /* Number six */
   {0x7e, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x00},
   /* Number seven */
   {0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00},
   /* Number eight */
   {0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x00},
   /* Number nine */
   {0x7e, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x7e, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7e, 0x00}
};

/* Objects */
Object racket[N_PLAYER] = {
   {L_PATTERN, C_RACKET, 0, POS_INIT_R_X, DISPLAY_HEIGHT / (DISPLAY_SCALE * MOVE_BALL_X), 0, 0, RED, sprite_racket_A, -1, -1},                                                                          /* Racket of player A */
   {L_PATTERN, C_RACKET, 0, DISPLAY_WIDTH / DISPLAY_SCALE - POS_INIT_R_X, DISPLAY_HEIGHT / (DISPLAY_SCALE * MOVE_BALL_X), 0, 0, BLUE, sprite_racket_B, -1, -1},                                         /* Racket of player B */
};

Object ball = { L_PATTERN, C_BALL, 0, DISPLAY_WIDTH / (2 * DISPLAY_SCALE) - L_PATTERN, 0, -MOVE_BALL_X, MOVE_BALL_Y, WHITE, sprite_ball, -1, -1 };                                                      /* Ping Pong Ball */

/*
 * main program
 * ---------------------------------------------------------------------------
 */
void main(void)
{
   /* initialization of the player's score */
   uint32_t i, push_state, led_state;
   for (i = 0; i < N_PLAYER; i++)
      racket[i].score = 0;
   push_state = 0;
   led_state = 0;

   initialize();

   while (1) {
      /* Determine if the ball can hit the racket */
      hit();
      /* Move the racket and display the new score */
      racket_score();
      /* Move the ball */
      move_ball();
      /* Draw the line, over and over as we can't yet read the video ram */
      draw_boundary();
      /* Judge the player to win or lose and calculate the score of each player */
      calculate_score();

      /* manage push buttons */
      push_state = push_button_get();
      if (push_state & 0x1)
         /* move up the racket */
         for (i = 0; i < N_PLAYER; i++)
            racket[i].dy = -MOVE_RAK;

      if (push_state & 0x2)
         /* move down the racket */
         for (i = 0; i < N_PLAYER; i++)
            racket[i].dy = +MOVE_RAK;

      /* manage leds' state */
      led_set(led_state);
      led_state++;
#ifdef ENV_QEMU
      timer_set_and_wait(TIMER_FREQ, 10);
#else
      timer_set_and_wait(TIMER_FREQ, 4);
#endif
   }
}

/* 
 * definition of functions
 * ---------------------------------------------------------------------------
 */

void write_pixel_scaling(uint32_t pixel, int x, int y)
{
   // #SCALING
   unsigned int i, j;

   for (i = 0; i < DISPLAY_SCALE; ++i) {
      for (j = 0; j < DISPLAY_SCALE; ++j) {
         const unsigned int real_y = y * DISPLAY_SCALE + i;
         const unsigned int real_x = x * DISPLAY_SCALE + j;
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
   return (void *)p;
}

/* function to clear entire screen to the selected color */
void clear_screen(uint32_t color)
{
   memset_32b(img, color, DISPLAY_WIDTH * DISPLAY_HEIGHT);
}

/* function to display the pixels of a pattern line of the ball */
void display_pattern_line(uint32_t m, int size_line, int x, int y, uint32_t color)
{
   int i;
   for (i = (size_line - 1); i >= 0; i--) {
      int new_color = ((m & 1) == 1) ? color : 0;
      m = m >> 1;
      write_pixel_scaling(new_color, (x + i), y);
   }
}

/* function to display the object considering the last background */
void display_pattern(uint32_t *pattern, int size_line, int size_colonne, int x, int y, uint32_t color)
{
   int i;
   for (i = 0; i < size_colonne; i++)
      display_pattern_line(pattern[i], size_line, x, y + i, color);
}

/* function to display the object */
void display_sprite(Object *object)
{
   int dx, dy;
   /* Initate the background of the object */
   if ((object->ax == -1) || (object->ay == -1))
      for (dx = 0; dx < object->size_l; dx++)
         for (dy = 0; dy < object->size_c; dy++)
            object->bg[dy][dx] = BLACK;

   if ((object->ax > -1 && object->ay > -1)
       && (object->x != object->ax || object->y != object->ay)) {
      for (dx = 0; dx < object->size_l; dx++) {
         for (dy = 0; dy < object->size_c; dy++) {
            write_pixel_scaling(object->bg[dy][dx], object->ax + dx, object->ay + dy);
         }
      }
   }
   object->ax = object->x;
   object->ay = object->y;

   display_pattern(object->pattern, object->size_l, object->size_c, object->x, object->y, object->color);
}

/* Draw a dividing line that distinguishes the player's game area */
void draw_boundary(void)
{
   uint32_t y;
   for (y = 0; y < DISPLAY_HEIGHT / DISPLAY_SCALE; y++) {
      if ((y % BOUNDARY < BOUNDARY / 2)) {
         write_pixel_scaling(0xffffff, (DISPLAY_WIDTH / (2 * DISPLAY_SCALE)), y);
      }
   }
}

/* To display the score of the players */
void display_score(Object *object, int player)
{
   uint32_t n = object->score, x;

   if (!player)
      x = DISPLAY_WIDTH / (DISPLAY_SCALE * 2) - SCORE_POS;                                                                                                                                              /* the abscissa of the position where the score of the player A shows */
   else
      x = DISPLAY_WIDTH / (DISPLAY_SCALE * 2) + SCORE_POS;                                                                                                                                              /* the abscissa of the position where the score of the player B shows */

   if (object->score > (MAX_DIGIT - 1))
      n = object->score = 0;
   display_pattern(sprite_number[n], (N_SIZE_LINE), (N_SIZE_COLONNE), x, SCORE_TOP, WHITE);
}

/* Put the ball into the initial position and the initial state */
void init_ball(void)
{
   ball.x = DISPLAY_WIDTH / (DISPLAY_SCALE * 2) - L_PATTERN;
   ball.y = 0;
   ball.dx = -MOVE_BALL_X;
}

/* Initiate the game */
void initialize(void)
{
   clear_screen(0);
   draw_boundary();
}

/* Determine if the shot is successful, if so, rebound the ball */
void hit(void)
{
   uint32_t i;

   /* Left and right edge impact */
   if ((ball.x - racket[0].x) == L_PATTERN) {
      if (((ball.y - racket[0].y) <= C_RACKET) && ((ball.y - racket[0].y) >= -C_BALL))
         ball.dx = +MOVE_BALL_X;
   } else if ((racket[1].x - ball.x) == L_PATTERN) {
      if (((ball.y - racket[1].y) <= C_RACKET) && ((ball.y - racket[1].y) >= -C_BALL))
         ball.dx = -MOVE_BALL_X;
   }

   /* Top and bottom edge imapct */
   for (i = 0; i < N_PLAYER; i++) {
      if ((abs(ball.x - racket[i].x) / L_PATTERN == 0))
         if ((racket[i].y - ball.y) / (C_BALL + 1) == 0)
            ball.dy = -MOVE_BALL_Y;
         else if ((ball.y - racket[i].y) / (C_BALL + 1) == 0)
            ball.dy = MOVE_BALL_Y;
   }

}

/* Move the racket of each player and display their score */
void racket_score(void)
{
   uint32_t i;

   /* Put the rackets into the window and move it */
   for (i = 0; i < N_PLAYER; i++) {
      display_sprite(&racket[i]);
      racket[i].y += racket[i].dy;
      racket[i].dy = 0;
      /* handle the situation that the racket arrive at the edge of the window */
      if (racket[i].y < 0)
         racket[i].y = 0;
      if (racket[i].y > ((DISPLAY_HEIGHT / DISPLAY_SCALE) - C_RACKET))
         racket[i].y = (DISPLAY_HEIGHT / DISPLAY_SCALE) - C_RACKET;

      /* display the score of players */
      display_score(&racket[i], i);
   }
}

/* function to move the ball */
void move_ball(void)
{
   /* Display the ball */
   display_sprite(&ball);

   /* Put the ball into the window and move it */
   ball.y += ball.dy;
   ball.x += ball.dx;

   /* handle the situation of edge reached */
   if (ball.y < 0) {
      ball.y = 0;
      ball.dy = +MOVE_BALL_Y;
   }
   if (ball.y > (DISPLAY_HEIGHT / DISPLAY_SCALE) - C_BALL) {
      ball.y = (DISPLAY_HEIGHT / DISPLAY_SCALE) - C_BALL;
      ball.dy = -MOVE_BALL_Y;
   }
}

/* fonction to calculate the score of each player */
void calculate_score(void)
{
   /* Justify if one of the players will win this round and count his score */
   /* this condition is reached when the ball is out of bounds in the opponent player's area */
   if (ball.x < 0) {
      init_ball();
      racket[1].score++;
   }
   if (ball.x > DISPLAY_WIDTH / DISPLAY_SCALE - L_PATTERN) {
      init_ball();
      racket[0].score++;
   }
}
