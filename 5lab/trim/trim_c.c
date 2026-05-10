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

    unsigned char* result = malloc(width * height * 3);

    if (result == NULL) {
        return NULL;
    }

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int src_index = ((y_start + y) * orig_width + (x_start + x)) * 3;
            int dst_index = (y * width + x) * 3;

            result[dst_index + 0] = img[src_index + 0]; // R
            result[dst_index + 1] = img[src_index + 1]; // G
            result[dst_index + 2] = img[src_index + 2]; // B
        }
    }

    return result;
}