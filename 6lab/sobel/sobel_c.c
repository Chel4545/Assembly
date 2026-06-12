#include <stdlib.h>
#include <string.h>

int sobel_c(const unsigned char* img, unsigned char* result, int width, int height) {
    if (img == NULL || result == NULL || width <= 0 || height <= 0) {
        return -1;
    }

    if (width < 3 || height < 3) {
        return 0;
    }

    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            //a b c
            //d e f
            //g h i
            int a = img[(y - 1) * width + (x - 1)];
            int b = img[(y - 1) * width + (x)];
            int c = img[(y - 1) * width + (x + 1)];

            int d = img[(y) * width + (x - 1)];
            int f = img[(y) * width + (x + 1)];

            int g = img[(y + 1) * width + (x - 1)];
            int h = img[(y + 1) * width + (x)];
            int i = img[(y + 1) * width + (x + 1)];

            //a b c    -1 0 1
            //d e f  * -2 0 2
            //g h i    -1 0 1
            int gx = -a + c - 2 * d + 2 * f - g + i;
            //a b c    -1-2-1
            //d e f  *  0 0 0
            //g h i     1 2 1
            int gy = -a - 2 * b - c + g + 2 * h + i;

            int value = abs(gx) + abs(gy);

            if (value > 255) {
                value = 255;
            }

            result[y * width + x] = (unsigned char)value;
        }
    }

    return 0;
}