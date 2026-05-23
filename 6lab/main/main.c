#include <stdio.h>
#include <stdlib.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image/stb_image_write.h"


int main(int argc, char* argv[]) {
    int width, height, channels;

    if (argc != 2) {
        printf("Использование: %s input.bmp output.bmp\n", argv[0]);
        return 1;
    }

    // считываем передаваемые параметры
    const char* input_file = argv[1];
    const char* output_file = argv[2];


    // получаем массив пикселей
    unsigned char *img = stbi_load(input_file, &width, &height, &channels, 1);
    if (img == NULL) {
        printf("Ошибка при открытии файла\n");
        return 1;
    }

    // Получаем результат
    unsigned char* result;

    if (!stbi_write_bmp(output_file, width, height, 3, result)) {
        printf("Ошибка при записи файла\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }

    free(result);
    stbi_image_free(img);

    return 0;
}