#ifndef SOBEL_H
#define SOBEL_H

int sobel_c(const unsigned char* img, unsigned char* result, int width, int height);
int sobel_asm(const unsigned char* img, unsigned char* result, int width, int height);
int sobel_asm_vector(const unsigned char* img, unsigned char* result, int width, int height);

#endif