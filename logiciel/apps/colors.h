#ifndef __COLORS_H__
#define __COLORS_H__

#include "cep_platform.h"

#if (PIXEL_SIZE == 4)
#define BLACK    0x0
#define WHITE    0xffffff
#define RED      0xff0000
#define BLUE     0xff
#define GREEN    0x00ff00
#define CYAN     0x0000ffff
#define MAGENTA  0x00ff00ff
#define YELLOW   0x00ffff00
#elif (PIXEL_SIZE == 2)
#define BLACK    0x0
#define WHITE    0x0000ffff
#define RED      0x0000f000
#define BLUE     0x0000003f
#define GREEN    0x00000fc0
#define CYAN     0x000007ff
#define MAGENTA  0x0000f03f
#define YELLOW   0x0000ffc0
#else
#error "unsupported pixel size"
#endif

#endif /* __COLORS_H__ */
