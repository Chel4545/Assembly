#include <stdlib.h>
#include <string.h>

unsigned char* sobel_c(const unsigned char* img, int width, int height) {
    if (img == NULL || width <= 0 || height <= 0) {
        return NULL;
    }

    unsigned char* result = calloc(width * height, sizeof(unsigned char));

    if (result == NULL) {
        return NULL;
    }

    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int a = img[(y - 1) * width + (x - 1)];
            int b = img[(y - 1) * width + (x)];
            int c = img[(y - 1) * width + (x + 1)];

            int d = img[(y) * width + (x - 1)];
            int f = img[(y) * width + (x + 1)];

            int g = img[(y + 1) * width + (x - 1)];
            int h = img[(y + 1) * width + (x)];
            int i = img[(y + 1) * width + (x + 1)];

            int gx = -a + c - 2 * d + 2 * f - g + i;
            int gy = -a - 2 * b - c + g + 2 * h + i;

            int value = abs(gx) + abs(gy);

            if (value > 255) {
                value = 255;
            }

            result[y * width + x] = (unsigned char)value;
        }
    }

    return result;
}