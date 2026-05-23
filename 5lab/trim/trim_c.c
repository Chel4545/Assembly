#include <stdlib.h>
#include "trim.h"

unsigned char* trim_c(
    const unsigned char* img,
    int orig_width,
    int width,
    int height,
    int x_start,
    int y_start
) {

    unsigned char* result = malloc(width * height);

    if (result == NULL) {
        return NULL;
    }

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int src_index = (y_start + y) * orig_width + (x_start + x);
            int dst_index = y * width + x;

            result[dst_index] = img[src_index]; 
        }
    }

    return result;
}