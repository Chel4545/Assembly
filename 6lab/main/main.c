#include <stdio.h>
#include <stdlib.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image/stb_image_write.h"

#include "sobel/sobel.h"


int main(int argc, char* argv[]) {
    int width, height, channels;

    if (argc != 3) {
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

    size_t image_size = (size_t)width * (size_t)height;

    // создаем результат
    unsigned char* result = calloc(image_size, sizeof(unsigned char));
    if (result == NULL) {
        printf("Ошибка выделения памяти\n");
        stbi_image_free(img);
        return 1;
    }

    // получаем результат
    #if USE_ASM_VECTOR == 1
    printf("Используем ассемблер с Vector\n");
    if (sobel_asm_vector(img, result, width, height) != 0) {
        printf("Ошибка при обработке изображения\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }
    #elif USE_ASM == 1
    printf("Используем ассемблер\n");
    if (sobel_asm(img, result, width, height) != 0) {
        printf("Ошибка при обработке изображения\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }
    #else
    printf("Используем си\n");
    if (sobel_c(img, result, width, height) != 0) {
        printf("Ошибка при обработке изображения\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }
    #endif

    if (!stbi_write_bmp(output_file, width, height, 1, result)) {
        printf("Ошибка при записи файла\n");
        free(result);
        stbi_image_free(img);
        return 1;
    }

    free(result);
    stbi_image_free(img);

    return 0;
}