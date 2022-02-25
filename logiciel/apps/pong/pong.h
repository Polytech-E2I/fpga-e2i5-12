#ifndef _PONG_H_
#define _PONG_H_

#include <stdint.h>

#define N_PLAYER        2       /* Nombre de joueurs */
#define L_PATTERN       4       /* The number of bits occupied by a row of objects */
#define C_RACKET       16       /* The number of bits occupied by a column of the racket */
#define C_BALL          4       /* The number of bits occupied by a column of the ball */
#define N_SIZE_LINE     8       /* The number of bits occupied by a row of numbers */
#define N_SIZE_COLONNE 16       /* The number of bits occupied by a column of numbers */
#define POS_INIT_R_X   20       /* The initial position of rackets */
#define SCORE_POS      30       /* The distance between the score and the middle of the window */
#define SCORE_TOP      10       /* The top position of the score */
#define SCORE_INT      10
#define MOVE_RAK        2       /* The distance each time you move the racket */
#define MAX_DIGIT      10       /* Number displayed as score */
#define MAX_FONT       16       /* Miximum size of the background */
#define BOUNDARY        8       /* Dotted line spacing */
#define MOVE_BALL_X     4       /* Horizontal distance each time you move the ball */
#define MOVE_BALL_Y     1       /* Vertical distance each time you move the ball */

typedef struct Object {
   int size_l, size_c;          /* Bit number of a line and a colonne */
   int score;
   int x, y;
   int dx, dy;
   uint32_t color;
   uint32_t *pattern;
   int ax, ay;
   uint32_t bg[MAX_FONT][L_PATTERN];
} Object;

/******************** Declare the functions ***********************/
extern void quit_application(void);
extern void write_pixel_scaling(uint32_t pixel, int x, int y);
extern void display_pattern_line(uint32_t m, int size_line, int x, int y, uint32_t color);
extern void display_object(uint32_t *pattern, int size_line, int size_colonne, int x, int y, uint32_t color);
extern void display_sprite(Object *object);
extern void draw_boundary(void);
extern void clear_screen(uint32_t color);
extern void display_score(Object *object, int player);
extern void init_ball(void);
extern void initialize(void);
extern void hit(void);
extern void racket_score(void);
extern void move_ball(void);
extern void calculate_score(void);
#endif
