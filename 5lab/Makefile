CC = gcc

BUILD_DIR = build

OPT ?= -O0

USE_ASM ?= 1

CFLAGS = -Wall -Wextra -std=c11 -I. $(OPT) -DUSE_ASM=$(USE_ASM)
LDFLAGS = -lm

COMMON_OBJS = \
	$(BUILD_DIR)/trim/trim_c.o \
	$(BUILD_DIR)/trim/trim_asm.o \
	$(BUILD_DIR)/int/parse_int.o

LAB5_OBJS = \
	$(BUILD_DIR)/main/main.o \
	$(COMMON_OBJS)

BENCH_OBJS = \
	$(BUILD_DIR)/tests/time.o \
	$(COMMON_OBJS)

.PHONY: all clean run bench

all: lab5 benchmark

main: lab5

time: benchmark

lab5: $(LAB5_OBJS)
	$(CC) $^ $(LDFLAGS) -o $@

benchmark: $(BENCH_OBJS)
	$(CC) $^ $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) lab5 benchmark