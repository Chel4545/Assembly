#include <stdio.h>
#include <stdlib.h>
#include "int/parse_int.h"
#include "trim/trim.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image/stb_image_write.h"

int main(int argc, char* argv[]) {
    int width, height, channels;

    if (argc != 7) {
        printf("Использование: %s input.bmp output.bmp x1 y1 x2 y2\n", argv[0]);
        return 1;
    }

    // считываем передаваемые параметры
    const char* input_file = argv[1];
    const char* output_file = argv[2];
    int x1, y1, x2, y2;

    if (!parse_int(argv[3], &x1) ||
        !parse_int(argv[4], &y1) ||
        !parse_int(argv[5], &x2) ||
        !parse_int(argv[6], &y2)) {
        printf("Ошибка при передачи координаты\n");
        printf("Использование: %s input.bmp output.bmp x1 y1 x2 y2\n", argv[0]);
        return 1;
    }

    // получаем массив пикселей
    unsigned char *img = stbi_load(input_file, &width, &height, &channels, 3);
    if (img == NULL) {
        printf("Ошибка при открытии файла\n");
        return 1;
    }

    // анализируем рабочую область
    int x_min = x1 < x2 ? x1 : x2;
    int x_max = x1 > x2 ? x1 : x2;

    int y_min = y1 < y2 ? y1 : y2;
    int y_max = y1 > y2 ? y1 : y2;

    if (x_min < 0 || x_max >= width || y_min < 0 || y_max >= height) {
        printf("Изображение: %s\n", input_file);
        printf("Размер: %d x %d пикселей\n", width, height);
        stbi_image_free(img);
        return 1;
    }

    int crop_width = x_max - x_min + 1;
    int crop_height = y_max - y_min + 1;

    // Получаем результат
    #if USE_ASM == 1
    printf("Используем ассемблер\n");
    unsigned char* result = trim_asm(img, width, crop_width, crop_height, x_min, y_min);
    if (result == NULL) {
        stbi_image_free(img);
        return 1;
    }
    #else
    printf("Используем си\n");
    unsigned char* result = trim_c(img, width, crop_width, crop_height, x_min, y_min);
    if (result == NULL) {
        stbi_image_free(img);
        return 1;
    }
    #endif

    if (!stbi_write_bmp(output_file, crop_width, crop_height, 3, result)) {
        printf("Ошибка при записи файла\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }

    free(result);
    stbi_image_free(img);

    return 0;
}