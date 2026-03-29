section .rodata
    message_file db 'Input file: '
    msg_len_file equ $ - message_file
    newline db 0x0a

section .bss
    buffer          resb 8

    file_name       resb 128

    single_word     resb 256
    single_word_len resb 1

    file_descriptor resq 1
    input_length    resq 1
    stack_base      resq 1

section .text
    global _start

_start:
    jmp menu
    .after_menu:
        jmp string
    .after_string:
        jmp ok

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
        mov rax, [input_length]
        add rsp, rax
        jmp string.while

    .end_while:
        jmp _start.after_string

check_palindrome:
    xor r8, r8                    ; r8 = текущая позиция в строке
    
    .skip_delims:
        cmp r8, [input_length]
        jae .end_check

        ; al = строка[r8]
        mov r10, [input_length]
        dec r10
        sub r10, r8
        mov r11, [stack_base]
        mov al, [r11 + r10]

        cmp al, 0x20                  ; space
        je .inc_skip
        cmp al, 0x09                  ; tab
        je .inc_skip
        jmp .word_start_found

    .inc_skip:
        inc r8
        jmp .skip_delims

    .word_start_found:
        mov r12, r8                   ; r12 = конец слова

    .find_word_end:
        cmp r12, [input_length]
        jae .word_end_found

        mov r10, [input_length]
        dec r10
        sub r10, r12
        mov r11, [stack_base]
        mov al, [r11 + r10]

        cmp al, 0x20
        je .word_end_found
        cmp al, 0x09
        je .word_end_found

        inc r12
        jmp .find_word_end

    .word_end_found:
        mov r13, r8
        mov r15, r12
        dec r15

    .check_word:
        cmp r13, r15
        jge .is_palindrome

        mov r10, [input_length]
        dec r10
        sub r10, r13
        mov r11, [stack_base]
        mov dl, [r11 + r10]

        mov r10, [input_length]
        dec r10
        sub r10, r15
        mov r11, [stack_base]
        mov al, [r11 + r10]

        cmp dl, al
        jne .not_palindrome

        inc r13
        dec r15
        jmp .check_word

    .is_palindrome:
        jmp write_file
    .after_write:
        mov r8, r12
        jmp .skip_delims

    .not_palindrome:
        mov r8, r12
        jmp .skip_delims

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
    mov qword [input_length], 0

    .read_loop:
        mov rax, 0
        mov rdi, 0
        mov rsi, buffer
        mov rdx, 8
        syscall

        test rax, rax
        jz .eof

        xor r9, r9

    .process_block:
        cmp r9, rax
        jae .read_loop

        mov bl, [buffer + r9]
        cmp bl, 0x0a
        je .line_done

        sub rsp, 1
        mov [rsp], bl
        inc qword [input_length]

        inc r9
        jmp .process_block

    .line_done:
        mov [stack_base], rsp
        mov rax, 1
        jmp .done

    .eof:
        cmp qword [input_length], 0
        je .no_data

        mov [stack_base], rsp
        mov rax, 1
        jmp .done

    .no_data:
        xor rax, rax

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

        mov r10, [input_length]
        dec r10
        sub r10, r9
        mov r11, [stack_base]
        add r11, r10

        mov rax, 1
        mov rdi, [file_descriptor]
        mov rsi, r11
        mov rdx, 1
        syscall

        inc r9
        jmp .write_loop

    .write_done:
        mov rax, 1
        mov rdi, [file_descriptor]
        mov rsi, newline
        mov rdx, 1
        syscall

        jmp check_palindrome.after_write

ok:
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall