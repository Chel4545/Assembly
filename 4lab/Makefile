ASM = lab4.asm
OBJ = lab4.o
BIN = lab4

SORT_DIR ?= 0

all: $(BIN)

$(BIN): $(OBJ)
	gcc -no-pie $(OBJ) -o $(BIN) -lm

$(OBJ): $(ASM)
	nasm -f elf64 -DSORT_DIR=$(SORT_DIR) $(ASM) -o $(OBJ)


run: $(BIN)
	./$(BIN)

debug: $(BIN)
	gdb ./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)