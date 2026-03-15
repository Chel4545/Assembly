ASM = lab1.asm
OBJ = lab1.o
BIN = lab1

SORT_DIR ?= 0

all: $(BIN)

$(BIN): $(OBJ)
	ld $(OBJ) -o $(BIN)

$(OBJ): $(ASM)
	nasm -f elf64 -DSORT_DIR=$(SORT_DIR) $(ASM) -o $(OBJ)

run: $(BIN)
	./$(BIN)

debug: $(BIN)
	gdb ./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)