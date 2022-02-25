#ifndef __BRICK_H__
#define __BRICK_H__

#include <stdint.h>


#define PATTERN_SIZE 24
#define BAR_L        24
#define BAR_C        6
#define BRICK_L      16
#define BRICK_C      8
#define BALL_L       4
#define BALL_C       4
#define MOVE_1       2
#define MOVE_2       1
#define MAX_BRICK    16
#define N_LEVEL      3
#define WALL_L       16
#define WALL_C       8

#define N_COLOR 4

/* object type definition used for ball, bar and bricks */
typedef struct object_t {
  uint32_t size_l, size_c;
  int      x, y; 
  int      dx, dy; 
  int      ax, ay;
  uint32_t color;
  uint32_t *pattern;
  uint32_t bg[BAR_C][PATTERN_SIZE]; /* background */
} object_t;

typedef struct brick_t {
  uint32_t exist;
  int      x, y;
  uint32_t color;
} brick_t;

/*
 * definition of functions' prototype
 * ---------------------------------------------------------------------------
 */
extern void write_pixel(int pixel, int x, int y);
extern void clear_screen(uint32_t color);
extern void initialize();
extern void display_pattern_line(uint32_t m,int x,int y,uint32_t color, uint32_t size_l);
extern void display_pattern(uint32_t *pattern, int x, int y, uint32_t color, uint32_t size_l, uint32_t size_c);
extern void display_sprite(object_t *object);
extern void led_set(uint32_t value);
extern void display_brick(brick_t *brick);
extern void destroy_brick(brick_t *brick);
extern void break_up(object_t *ball, brick_t *brick);
extern void build_wall(uint32_t *canvas);
extern void put_bar_ball(object_t *ball, object_t *bar);
extern void build(object_t *ball, object_t *bar);
extern void move_bar(object_t *bar);
extern void move_ball(object_t *ball);
extern void bar_catch(object_t *ball, object_t *bar);
extern void ball_on_bar(object_t *ball, object_t *bar);
  
#endif /* __BRICK_H__ */
