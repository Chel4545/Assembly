section .rodata
    message_file db 'Input file: '
    msg_len_file equ $ - message_file  

;section .data

section .bss
    buffer          resb 128
    file_name       resb 128

    single_word     resb 128
    single_word_len resb 1

    file_descriptor resq 1
    input_length    resq 1

section .text
    global _start

_start:
    call menu
    call string
    jmp ok

menu:
    call output_console_message
    call input_console_string
    test rax, rax
    jz ok
    call make_file_name
    call make_file
    ret

string:
    .while:
        call input_console_string
        cmp rax, 0
        je .end_while

        call check_palindrome
        jmp .while

    .end_while:
    ret

check_palindrome:
    xor r9, r9 ; индекс символа в буфере
    .while:
        cmp r9, [input_length]
        jge .end_while

        call get_word
        call check_single_word_palindrome
        cmp rax, 0
        jne .skip_write
        call write_file
        .skip_write:
        jmp .while

    .end_while:
    ret

check_single_word_palindrome:
    movzx rcx, byte [single_word_len]
    mov rbx, rcx
    shr rcx, 1              ; rcx = length / 2
    xor r8b, r8b
    .while:
        cmp r8b, cl
        jge .end_while_success

        mov al, [single_word + r8]

        sub rbx, r8
        dec rbx              ; rbx = length - r8 - 1
        mov bl, [single_word + rbx]

        cmp al, bl

        jne .end_while_failure
        inc r8b
        jmp .while

    .end_while_success:
        xor rax, rax
        ret
    .end_while_failure:
        mov rax, 1
        ret

get_word: ; r9 - индекс текущего символа

    lea rsi, [buffer + r9*1]    
    lea rdi, [single_word] 
    xor rcx, rcx

    .while:
        mov al, [rsi]

        cmp al, 0x20 ; ' '
            je .end_while
        cmp al, 0x9  ; '\t'
            je .end_while
        cmp al, 0x0a ; '\n'
            je .end_while
        cmp al, 0x00 ; '\0'
            je .end_while

        mov [rdi], al
        inc rsi
        inc rdi
        inc rcx
        jmp .while

    .end_while:
    cmp rcx, 0
    je .no_word
    mov r9, rsi
    sub r9, buffer
    mov [single_word_len], cl
    ret
    .no_word:
    inc r9
    ret

output_console_message:
    mov rax, 1         
    mov rdi, 1          
    mov rsi, message_file 
    mov rdx, msg_len_file 
    syscall
    ret

input_console_string:
    mov rax, 0         
    mov rdi, 0          
    mov rsi, buffer
    mov rdx, 128
    syscall
    mov [input_length], rax  ; сохраняем реальную длину введенных данных
    ret

make_file:
    mov rax, 2          
    mov rdi, file_name         
    mov rsi, 0x242   ; флаг(инфа ядру)  
    mov rdx, 0777    ; права доступа  
    syscall
    mov [file_descriptor], rax  ; дескриптор файла
    ret

make_file_name:
    lea rsi, [buffer]    
    lea rdi, [file_name] 
    xor rcx, rcx        

    copy_loop:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        test al, al
        jnz copy_loop
    
    ret

write_file:
    mov rax, 1          
    mov rdi, [file_descriptor]
    mov rsi, buffer
    mov rdx, [input_length]
    syscall
    ret


;системные вызовы для выхода
ok:
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall