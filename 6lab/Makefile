CC = gcc

BUILD_DIR = build

OPT ?= -O0
IMPL ?= c

CFLAGS = -Wall -Wextra -std=c11 -I. $(OPT)
LDFLAGS = -lm

ifeq ($(IMPL),c)
	SOBEL_OBJ = $(BUILD_DIR)/sobel/sobel_c.o
	CFLAGS += -DUSE_ASM=0 -DUSE_ASM_VECTOR=0
else ifeq ($(IMPL),asm)
	SOBEL_OBJ = $(BUILD_DIR)/sobel/sobel_asm.o
	CFLAGS += -DUSE_ASM=1 -DUSE_ASM_VECTOR=0
else ifeq ($(IMPL),vector)
	SOBEL_OBJ = $(BUILD_DIR)/sobel/sobel_asm_vector.o
	CFLAGS += -DUSE_ASM=0 -DUSE_ASM_VECTOR=1 -msse2
else
	$(error Unknown IMPL=$(IMPL). Use IMPL=c, IMPL=asm or IMPL=simd)
endif

LAB5_OBJS = \
	$(BUILD_DIR)/main/main.o \
	$(SOBEL_OBJ)

BENCH_OBJS = \
	$(BUILD_DIR)/time/time.o \
	$(BUILD_DIR)/sobel/sobel_c.o \
	$(BUILD_DIR)/sobel/sobel_asm.o \
	$(BUILD_DIR)/sobel/sobel_asm_vector.o

.PHONY: all clean run bench main time

all: lab5

main: lab5

time: benchmark

bench: benchmark

lab5: $(LAB5_OBJS)
	$(CC) $^ $(LDFLAGS) -o $@

benchmark: $(BENCH_OBJS)
	$(CC) $^ $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) lab5 benchmark