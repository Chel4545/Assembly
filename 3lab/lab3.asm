section .rodata
    message_file db 'Input file: '
    msg_len_file equ $ - message_file
    newline db 0x0a  

;section .data

section .bss
    buffer          resb 8
    buffer_len      resb 1

    file_name       resb 128

    single_word     resb 256
    single_word_len resb 1

    file_descriptor resq 1
    input_length    resq 1

section .text
    global _start

_start:
    jmp menu
	.after_menu:
    jmp string

menu:
    jmp output_console_message
	.after_output:
    jmp input_console_file_name
	.after_input_file_name:
    test rax, rax
    jz ok
    jmp make_file
	.after_make_file:
    jmp _start.after_menu

string:
	.while:
    jmp input_console_string
	.after_input_string:
    cmp rax, 0
    je .end_while

    jmp check_palindrome
	.after_check_p:

	.end_while:
    jmp string.after_check_p

check_palindrome:
    mov r9, [buffer_len]
    imul r9, 8
    mov r10, rsp
    sub r10, r9 ; r10 - начало строки

    xor r8, r8

    .while_start_tab:
        cmp r8, [input_length]
        jae .end_check_start_tab
        mov al, [r10 + r8]
        cmp al, 0x20          
        je .inc_left
        cmp al, 0x09   
        je .inc_left
        jmp .end_check_start_tab

    .inc_left:
        inc r8
        jmp .while_start_tab


    .end_check_start_tab:

	.while:
		cmp r8, [input_length]
		jae .end_check

		; найти конец слова
		mov r12, r8
	    .find_word_end:
			cmp r12, [input_length]
			jae .word_end_found
			mov al, [r10 + r12]
			cmp al, 0x20
			je .word_end_found
			cmp al, 0x09
			je .word_end_found
			inc r12
			jmp .find_word_end

	.word_end_found:
		; проверить палиндром слова
		mov r13, r8
		mov r15, r12
		dec r15

	.check_word:
			cmp r13, r15
			jge .is_palindrome

			mov al, [r10 + r13]
			mov bl, [r10 + r15]
			cmp al, bl
			jne .not_palindrome

			inc r13
			dec r15
			jmp .check_word

	.is_palindrome:
		jmp write_file
	.after_write:
		; пропустить пробелы после слова
		mov r8, r12
	.skip_spaces:
			cmp r8, [input_length]
			jae .while
			mov al, [r10 + r8]
			cmp al, 0x20
			je .is_space
			cmp al, 0x09
			je .is_space
			jmp .while
	.is_space:
			inc r8
			jmp .skip_spaces

	.not_palindrome:
		; пропустить пробелы после слова
		mov r8, r12
	.skip_spaces_not:
			cmp r8, [input_length]
			jae .while
			mov al, [r10 + r8]
			cmp al, 0x20
			je .is_space_not
			cmp al, 0x09
			je .is_space_not
			jmp .while
	.is_space_not:
			inc r8
			jmp .skip_spaces_not

	.end_check:
		jmp string.after_check_p


output_console_message:
    mov rax, 1
    mov rdi, 1
    mov rsi, message_file
    mov rdx, msg_len_file
    syscall
    jmp menu.after_output

input_console_file_name:
    mov rax, 0
    mov rdi, 0
    mov rsi, file_name
    mov rdx, 128
    syscall
    jmp menu.after_input_file_name

input_console_string:
    lea r8, [buffer]
    xor rcx, rcx

	.read_loop:
        mov rax, 0
        mov rdi, 0
        mov rsi, r8
        mov rdx, 8
        syscall

        test rax, rax
        jz .end

        xor r9, r9

	    .find_newline:
            cmp r9, rax
            jge .no_newline_in_block

            mov al, [r8 + r9]
            cmp al, 0x0a
            je .found_newline_at_pos

            inc r9
        jmp .find_newline

	    .found_newline_at_pos:
            add byte [buffer_len], 1
            add rcx, r9
            add rcx, 1
            mov [input_length], rcx
            jmp .done

        .no_newline_in_block:
            add byte [buffer_len], 1
            add rcx, rax
            add r8, 8
            jmp .read_loop

    .end:
    mov [input_length], rcx

    .done:
    jmp string.after_input_string

make_file:
    mov rax, 2
    mov rdi, file_name
    mov rsi, 0x242
    mov rdx, 0777
    syscall
    mov [file_descriptor], rax
    jmp menu.after_make_file

close_file:
    mov rax, 3
    mov rdi, [file_descriptor]
    syscall
    jmp menu.after_make_file

write_file:
    ; r8 - начало слова, r12 - конец слова, r10 - начало буфера
    mov r9, r8
	.write_loop:
		cmp r9, r12
		jae .write_done
		mov rax, 1
		mov rdi, [file_descriptor]
		lea rsi, [r10 + r9]
		mov rdx, 1
		syscall
		inc r9
		jmp .write_loop

	.write_done:
		; добавить новую строку
		mov rax, 1
		mov rdi, [file_descriptor]
		lea rsi, [newline]
		mov rdx, 1
		syscall
		jmp check_palindrome.after_write


;системные вызовы для выхода
ok:
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall