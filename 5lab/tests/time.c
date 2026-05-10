#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "../trim/trim.h"

#define STB_IMAGE_IMPLEMENTATION
#include "../stb_image/stb_image.h"

#define ITERATIONS 1000

#define FILE1 "data/file1.bmp"
#define FILE2 "data/file2.bmp"
#define FILE3 "data/file3.bmp"
#define FILE4 "data/file4.bmp"
#define FILE5 "data/file5.bmp"

typedef struct {
    const char* name;
    const char* filename;
} ImageTest;

typedef struct {
    const char* name;
    int x_min;
    int y_min;
    int x_max;
    int y_max;
} CropTest;

double measure_c(const unsigned char* img, int width, int crop_width, int crop_height, int x_min, int y_min) {
    clock_t start = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        unsigned char* tmp = trim_c(img, width, crop_width, crop_height, x_min, y_min);

        if (tmp == NULL) {
            return -1.0;
        }

        free(tmp);
    }

    clock_t end = clock();

    return ((double)(end - start) / CLOCKS_PER_SEC);
}

double measure_asm(const unsigned char* img, int width, int crop_width, int crop_height, int x_min, int y_min) {
    clock_t start = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        unsigned char* tmp = trim_asm(img, width, crop_width, crop_height, x_min, y_min);

        if (tmp == NULL) {
            return -1.0;
        }

        free(tmp);
    }

    clock_t end = clock();

    return ((double)(end - start) / CLOCKS_PER_SEC);
}

int main(void) {
    ImageTest images[] = {
        {"file1", FILE1},
        {"file2", FILE2},
        {"file3", FILE3},
        {"file4", FILE4},
        {"file5", FILE5}
    };

    CropTest crops[] = {
        {"100x100", 200, 200, 299, 299},
        {"200x200", 150, 150, 349, 349},
        {"300x300", 100, 100, 399, 399},
        {"400x400",  50,  50, 449, 449},
        {"500x500",   0,   0, 499, 499}
    };

    int image_count = sizeof(images) / sizeof(images[0]);
    int crop_count = sizeof(crops) / sizeof(crops[0]);

    printf("ITERATIONS = %d\n\n", ITERATIONS);

    printf("| Файл  |   img   |  crops  |  C, мс  | ASM, мс |  accel  |\n");

    for (int i = 0; i < image_count; i++) {
        int width, height, channels;

        unsigned char* img = stbi_load(
            images[i].filename,
            &width,
            &height,
            &channels,
            3
        );

        if (img == NULL) {
            printf("Ошибка: не удалось открыть файл %s\n", images[i].filename);
            continue;
        }

        for (int j = 0; j < crop_count; j++) {
            int x_min = crops[j].x_min;
            int y_min = crops[j].y_min;
            int x_max = crops[j].x_max;
            int y_max = crops[j].y_max;


            int crop_width = x_max - x_min + 1;
            int crop_height = y_max - y_min + 1;

            double time_c = measure_c(
                img,
                width,
                crop_width,
                crop_height,
                x_min,
                y_min
            );

            if (time_c < 0.0) {
                printf("Ошибка: trim_c вернула NULL\n");
                stbi_image_free(img);
                return 1;
            }

            double time_asm = measure_asm(
                img,
                width,
                crop_width,
                crop_height,
                x_min,
                y_min
            );

            if (time_asm < 0.0) {
                printf("Ошибка: trim_asm вернула NULL\n");
                stbi_image_free(img);
                return 1;
            }

            double speedup = time_c / time_asm;

            printf("| %s | %dx%d | %s | %.5f | %.5f |  %.2fx  |\n",
                   images[i].name,
                   width,
                   height,
                   crops[j].name,
                   time_c,
                   time_asm,
                   speedup);
        }

        stbi_image_free(img);
    }

    return 0;
}