#include <stdlib.h>
#include <errno.h>
#include <limits.h>

int parse_int(const char* s, int* result) {
    char* endptr;
    long value;

    if (s == NULL || s[0] == '\0') {
        return 0;
    }

    errno = 0;
    value = strtol(s, &endptr, 10);

    if (errno != 0) {
        return 0;
    }

    if (*endptr != '\0') {
        return 0;
    }

    if (value < INT_MIN || value > INT_MAX) {
        return 0;
    }

    *result = (int)value;
    return 1;
}