#include "snake.h"
#include "cep_platform.h"
#include "colors.h"

#include <stdint.h>

#ifdef ENV_QEMU
#include <string.h>
#include <stdio.h>
#endif

/* definition of bitmap for each line in the 4 x 4 pattern */
uint32_t carre[PATTERN_SIZE]  = { 0xf, 0xf, 0xf, 0xf };
uint32_t head[PATTERN_SIZE]   = { 0xf, 0xd, 0xf, 0xf }; // snake head
uint32_t fruit[PATTERN_SIZE]  = { 0x4, 0xf, 0x7, 0x7};

/*
 * definition of macros
 * ---------------------------------------------------------------------------
 */

#define DISPLAY_SCALE  1

#define DW_UNSCALED    (DISPLAY_WIDTH  / DISPLAY_SCALE)
#define DH_UNSCALED    (DISPLAY_HEIGHT / DISPLAY_SCALE)

// Pointers to the peripherals base address
// Video Memory
volatile uint32_t *img = (volatile uint32_t *)VRAM_OFFSET;

Object body[MAX_LONG];          /* The array which stores the information about the snakes' body */
Snake snake_body;               /* This variable of type Snake registers the information of the whole snake body */
Snake *s = &snake_body;         /* A pointer that points to the variable snake_body */
Object food;                    /* The variable which contains the information of the food which will be eaten by the snake */
uint32_t put;                   /* This is a flag to indicate that the food had been put into one place */
static unsigned long next = 1;  /* RAND_MAX assumed to be 32767, to obtain a random value */

/*
 * main program
 * ---------------------------------------------------------------------------
 */
void main(void)
{

   uint32_t i, led_state;
   uint32_t push_state, previous_push_state;
   led_state = 0;
   uint32_t latency = 20;

   start();
   push_state = push_button_get();

   while (1) {
      /* Record push-button state to act only on the "press" event */
      previous_push_state = push_state;
      push_state = push_button_get();

      if (push_state != previous_push_state) {
         /* Assume no two buttons are pressed at the same time */
         if (push_state & 0x1) {
            /* to right */
            switch (s->direct) {
            case SOUTH:
               s->direct = WEST;
               break;
            case NORTH:
               s->direct = EAST;
               break;
            case WEST:
               s->direct = NORTH;
               break;
            case EAST:
               s->direct = SOUTH;
               break;
            }
         }

         if (push_state & 0x2) {
            /* to left */
            switch (s->direct) {
            case SOUTH:
               s->direct = EAST;
               break;
            case NORTH:
               s->direct = WEST;
               break;
            case WEST:
               s->direct = SOUTH;
               break;
            case EAST:
               s->direct = NORTH;
               break;
            }
         }
      }

      /* According to the direction of the snake, move it */
      move_snake();

      /* Arrange the situation when the snake touch the food */
      latency -= eat_food();

      /* Determine if the game is over */
      game_over();
      if (s->dead || (s->size >= MAX_LONG)) {
         /* If the snake has bit itself, the game should be restarted */
         clear_screen(RED);
#ifdef ENV_QEMU
         timer_set_and_wait(TIMER_FREQ, 2000);
#else
         timer_set_and_wait(TIMER_FREQ, 200);
#endif
         start();
         latency = 20;
      }

      /* Display objects. */
      for (i = 0; i < s->size; i++)
         display_sprite(&body[i]);

      display_sprite(&food);

      led_set(led_state);
      led_state++;

      timer_set_and_wait(TIMER_FREQ, latency);
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
         if (real_y * DISPLAY_WIDTH + real_x >= (DISPLAY_WIDTH * DISPLAY_HEIGHT)) {
            // Out of bound access to memory video
#ifdef ENV_QEMU
            printf("real_x : %ld\n", real_x);
            printf("real_y : %ld\n", real_y);
#endif
         } else {
            img[real_y * DISPLAY_WIDTH + real_x] = pixel;
         }
      }
   }
}

void *memset_32b(volatile uint32_t *dest, uint32_t c, uint32_t n)
{
   volatile uint32_t *p = dest;
   while (n-- > 0) {
      *(volatile uint32_t *)dest++ = c;
   }
   return (void *) p;
}

/* function to clear entire screen to the selected color */
void clear_screen(uint32_t color)
{
   memset_32b(img, color, DISPLAY_WIDTH * DISPLAY_HEIGHT);
}

/* function to display the pixels of a pattern line of the ball */
void display_pattern_line(uint32_t m, uint32_t x, uint32_t y, uint32_t color)
{
   uint32_t i;
   for (i = 0; i < PATTERN_SIZE; i++) {
      uint32_t new_color = ((m & 1) == 1) ? color : 0;
      m = m >> 1;
      write_pixel(new_color, x + i, y);
   }
}

/* function to display the object considerting the last background */
void display_pattern(uint32_t *pattern, uint32_t x, uint32_t y, uint32_t color)
{
   uint32_t i;
   for (i = 0; i < PATTERN_SIZE; i++)
      display_pattern_line(pattern[i], x, y + i, color);
}

/* function to display an 8x8 object */
void display_sprite(Object *object)
{
   uint32_t dx, dy;

   if ((object->x != object->ax) || (object->y != object->ay)) {
      for (dx = 0; dx < PATTERN_SIZE; dx++) {
         for (dy = 0; dy < PATTERN_SIZE; dy++) {
            write_pixel(object->bg[dx][dy], object->ax + dx, object->ay + dy);
         }
      }

      object->ax = object->x;
      object->ay = object->y;
   }

   display_pattern(object->pattern, object->x, object->y, object->color);
}

/* Allocate a square for the body of the snake */
void alloc_square(Object *object, uint32_t x, uint32_t y, uint32_t color, uint32_t *pattern)
{

   uint32_t dx, dy;

   object->ax = object->x = x;
   object->ay = object->y = y;
   object->color = color;
   object->pattern = pattern;

   for (dx = 0; dx < PATTERN_SIZE; dx++)
      for (dy = 0; dy < PATTERN_SIZE; dy++)
         //object->bg[dx][dy] = read_pixel(object->x + dx, object->y + dy);
         object->bg[dx][dy] = 0;
}

/* Add a square to the snake's body */
void add_body(Object *body_old, Object *body_new)
{

   uint32_t dx, dy;

   alloc_square(body_new, body_old->ax, body_old->ay, body_old->color, body_old->pattern);
   for (dx = 0; dx < PATTERN_SIZE; dx++)
      for (dy = 0; dy < PATTERN_SIZE; dy++)
         body_new->bg[dx][dy] = body_old->bg[dx][dy];
}

/* Test if there are two patterns overlapped. */
uint32_t overlap(Object *object1, Object *object2)
{
   if ((object1->x > (object2->x - PATTERN_SIZE)) && (object1->x < (object2->x + PATTERN_SIZE)))
      if ((object1->y > (object2->y - PATTERN_SIZE)) && (object1->y < (object2->y + PATTERN_SIZE)))
         return 1;

   return 0;
}

/* generate a random number */
uint32_t random_num(uint32_t max)
{
   next = RAND_FACTOR + (body[s->size - 1].x << 1);
   while (next <= 0)
      next += max;
   while (next > max)
      next -= max;
   return next;
}

/* Place the food in window. */
void place_food(void)
{
   uint32_t i;

   do {
      put = 0;
      for (i = 0; i < s->size; i++)
         if (overlap(&body[i], &food))
            put = 1;
      food.x = random_num(DW_UNSCALED - PATTERN_SIZE);
      food.y = random_num(DH_UNSCALED - PATTERN_SIZE);
   } while (put);
}

/* Initialize the configurations of the game. */
void start(void)
{
   clear_screen(0);

   /* Initialize each square that makes up the snake's body. */
   uint32_t i;
   for (i = 0; i < INIT_SIZE; i++)
      if (i == 0)
         /* the head */
         alloc_square(&body[i], DW_UNSCALED / 2, INIT_POSITION - i * PATTERN_SIZE, GREEN, head);
      else
         /* the body */
         alloc_square(&body[i], DW_UNSCALED / 2, INIT_POSITION - i * PATTERN_SIZE, RED, carre);

   /* Initialize the whole body of the snake. */
   s->head = &body[0];
   s->direct = SOUTH;
   s->size = INIT_SIZE;
   s->dead = 0;

   /* Place the food. */
   alloc_square(&food, 0, 0, YELLOW, fruit);
   place_food();
}

/* The function to move the head and the body of the snake */
void move_snake(void)
{
   /* Determine the direction the snake is moving */
   switch (s->direct) {
   case SOUTH:
      s->head->y += PATTERN_SIZE;
      break;
   case NORTH:
      s->head->y -= PATTERN_SIZE;
      break;
   case EAST:
      s->head->x += PATTERN_SIZE;
      break;
   case WEST:
      s->head->x -= PATTERN_SIZE;
      break;
   }

   uint32_t i;

   /* When the snake arrive at the edge of the window, it stops moving, if not, its body follows its head */
   if ((s->head->y < 0)
       || (s->head->y > DH_UNSCALED - PATTERN_SIZE)
       || (s->head->x < 0)
       || (s->head->x > DW_UNSCALED - PATTERN_SIZE)) {
      s->dead = 1;
   } else {
      for (i = 1; i < s->size; i++) {
         body[i].y = body[i - 1].ay;
         body[i].x = body[i - 1].ax;
      }
   }
}

/*
 * The function to determine if the snake has eaten the food,
 * if so, the body of the snake will lengthen,
 * at the same time, we put a new food at a new random area.
 * The return value is used to increase speed
 */
uint32_t eat_food(void)
{
   /* Lengthen the body of the snake */
   if (overlap(s->head, &food)) {
      s->size++;
      add_body(&body[(s->size - 2)], &body[(s->size - 1)]);

      /* Rearranging the food */
      place_food();
      return 1;
   } else {
      return 0;
   }
}

/* Determine if the game is over */
void game_over(void)
{
   for (uint32_t i = 1; i < s->size; i++)
      /* If the snake eats its own body. */
      if (overlap(s->head, &body[i]))
         s->dead = 1;
}
