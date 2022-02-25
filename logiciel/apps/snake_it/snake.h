#ifndef __SNAKE_H__
#define __SNAKE_H__

#include <stdint.h>

#define INIT_SIZE     3   // The initial length of the snake.
#define MAX_LONG      35  // The maximum length of the snake.
#define PATTERN_SIZE  4   // The size of the patterns.
#define INIT_POSITION 20  // The Initial position of the snake.
#define RAND_FACTOR   40  // The factor to calculate the random value.

#define SOUTH         1
#define NORTH         2
#define WEST          3
#define EAST          4

#define RED           0xFF0000
#define GREEN         0x00FF00
#define OLIVE         0xCCCC00 


/* object type definition used for each piece of the snake and the food */
typedef struct Object {
  uint32_t x, y;
  uint32_t ax, ay;
  uint32_t color;
  uint32_t *pattern;
  uint32_t bg[PATTERN_SIZE][PATTERN_SIZE]; /* background */
} Object;

/* struct snake contains the informations of the whole snake */ 
typedef struct Snake {
  Object *head;
  uint32_t direct;
  uint32_t size;
  uint32_t dead;
}Snake;

/* -----------------------------------------------------------------------------
 * ---------------------------Declarations of fonctions-------------------------
 * ----------------------------------------------------------------------------- */
extern int      read_pixel(int x,int y);
extern void     write_pixel(int pixel,int x,int y);
extern void     clear_screen(uint32_t color);
extern void     display_pattern_line(uint32_t m, uint32_t x, uint32_t y, uint32_t color);
extern void     display_pattern(uint32_t *pattern, uint32_t x, uint32_t y, uint32_t color);
extern void     display_sprite(Object *object);
extern void     alloc_square(Object *object, uint32_t x, uint32_t y, uint32_t color, uint32_t *pattern);
extern uint32_t overlap(Object *object1, Object *object2);
extern void     add_body(Object *body_old, Object *body_new);

/* Functions to run the game. */
extern uint32_t random_num(uint32_t max);
extern void     place_food(void);
extern void     start(void);
extern void     move_snake(void);
extern uint32_t eat_food(void);
extern void     game_over(void);
  
#endif /* __SNAKE_H__ */
