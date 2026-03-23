ASM = lab3.asm
OBJ = lab3.o
BIN = lab3
RES = file

SORT_DIR ?= 0

all: $(BIN)

$(BIN): $(OBJ)
	ld $(OBJ) -o $(BIN)

$(OBJ): $(ASM)
	nasm -f elf64 -DSORT_DIR=$(SORT_DIR) $(ASM) -o $(OBJ)

run: $(BIN)
	rm -f $(RES)
	./$(BIN)

debug: $(BIN)
	gdb ./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)