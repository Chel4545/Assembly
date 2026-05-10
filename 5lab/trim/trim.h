#ifndef LAB5_GRAYSCALE_H
#define LAB5_GRAYSCALE_H

unsigned char* trim_c(
    const unsigned char* img,
    int orig_width,
    int width,
    int height,
    int x_start,
    int y_start
);

unsigned char* trim_asm(
    const unsigned char* img,
    int orig_width,
    int width,
    int height,
    int x_start,
    int y_start
);

#endif