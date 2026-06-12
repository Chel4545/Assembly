#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "sobel/sobel.h"

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


double measure_c(const unsigned char* img, unsigned char* result, int width, int height) {
    clock_t start = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        if (sobel_c(img, result, width, height) != 0) {
            return -1.0;
        }
    }

    clock_t end = clock();

    return ((double)(end - start) / CLOCKS_PER_SEC);
}

double measure_asm(const unsigned char* img, unsigned char* result, int width, int height) {
    clock_t start = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        if (sobel_asm(img, result, width, height) != 0) {
            return -1.0;
        }
    }

    clock_t end = clock();

    return ((double)(end - start) / CLOCKS_PER_SEC);
}

double measure_asm_vector(const unsigned char* img, unsigned char* result, int width, int height) {
    clock_t start = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        if (sobel_asm_vector(img, result, width, height) != 0) {
            return -1.0;
        }
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


    int image_count = sizeof(images) / sizeof(images[0]);

    printf("ITERATIONS = %d\n\n", ITERATIONS);

    printf("| Файл  | Размер      | C, мс     | ASM, мс   | Vector, мс | Check |\n");
    printf("|-------|-------------|-----------|-----------|------------|-------|\n");

    for (int i = 0; i < image_count; i++) {
        int width, height, channels;

        unsigned char* img = stbi_load(
            images[i].filename,
            &width,
            &height,
            &channels,
            1
        );

        if (img == NULL) {
            printf("Ошибка: не удалось открыть файл %s\n", images[i].filename);
            continue;
        }

        if (width <= 0 || height <= 0 || (size_t)width > SIZE_MAX / (size_t)height) {
            printf("Ошибка: некорректный размер изображения %s\n", images[i].filename);
            stbi_image_free(img);
            continue;
        }

        size_t image_size = (size_t)width * (size_t)height;

        unsigned char* result_c = calloc(image_size, sizeof(unsigned char));
        unsigned char* result_asm = calloc(image_size, sizeof(unsigned char));
        unsigned char* result_vector = calloc(image_size, sizeof(unsigned char));

        if (result_c == NULL || result_asm == NULL || result_vector == NULL) {
            printf("Ошибка выделения памяти\n");

            free(result_c);
            free(result_asm);
            free(result_vector);
            stbi_image_free(img);

            return 1;
        }

        double time_c = measure_c(img, result_c, width, height);
        if (time_c < 0.0) {
            printf("Ошибка: sobel_c вернула ошибку\n");

            free(result_c);
            free(result_asm);
            free(result_vector);
            stbi_image_free(img);

            return 1;
        }

        double time_asm = measure_asm(img, result_asm, width, height);
        if (time_asm < 0.0) {
            printf("Ошибка: sobel_asm вернула ошибку\n");

            free(result_c);
            free(result_asm);
            free(result_vector);
            stbi_image_free(img);

            return 1;
        }

        double time_vector = measure_asm_vector(img, result_vector, width, height);
        if (time_vector < 0.0) {
            printf("Ошибка: sobel_asm_vector вернула ошибку\n");

            free(result_c);
            free(result_asm);
            free(result_vector);
            stbi_image_free(img);

            return 1;
        }

        int same_asm = memcmp(result_c, result_asm, image_size) == 0;
        int same_vector = memcmp(result_c, result_vector, image_size) == 0;

        const char* check = (same_asm && same_vector) ? "OK" : "DIFF";

        printf("| %-5s | %5dx%-5d | %9.5f | %9.5f | %10.5f | %-5s |\n",
               images[i].name,
               width,
               height,
               time_c,
               time_asm,
               time_vector,
               check);

        free(result_c);
        free(result_asm);
        free(result_vector);
        stbi_image_free(img);
    }

    return 0;
}