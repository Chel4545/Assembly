CC = gcc

BUILD_DIR = build

OPT ?= -O0

CFLAGS = -Wall -Wextra -std=c11 -I. $(OPT)
LDFLAGS = -lm

LAB5_OBJS = \
	$(BUILD_DIR)/main/main.o \

BENCH_OBJS = \
	$(BUILD_DIR)/tests/time.o \

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