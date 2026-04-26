INPUT_BUF_SIZE  equ 12
OUTPUT_BUF_SIZE equ 12
FILE_NAME_SIZE  equ 10

SYS_READ  equ 0
SYS_WRITE equ 1
SYS_OPEN  equ 2
SYS_CLOSE equ 3
SYS_EXIT  equ 60

STDIN  equ 0
STDOUT equ 1

SPACE equ 0x20
TAB   equ 0x09
LF    equ 0x0A
CR    equ 0x0D
ZR    equ 0x00

O_CREAT  equ 64
O_TRUNC  equ 512
O_RDWR   equ 2

section .rodata
    message_file db 'Input file: '
    msg_len_file equ $ - message_file

section .bss
    input_buffer    resb INPUT_BUF_SIZE
    len_input       resq 1

    output_buffer   resb OUTPUT_BUF_SIZE
    len_output      resq 1

    file_name       resb FILE_NAME_SIZE
    file_descriptor resq 1

section .text
    global _start

_start:
    call menu
    call input_console_string
    call close_file
    jmp ok

menu:
    push rbp
    mov  rbp, rsp

    call output_console_message
    call input_console_file_name

    test rax, rax
    jz ok

    call make_file
    
    mov rsp, rbp
    pop rbp
    ret

check_palindrome:
    push rbp
    mov  rbp, rsp

    push rax
    push rbx
    push rcx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13

    mov r11, input_buffer         ; r11 = адрес начала буфера для чтения
    mov r12, output_buffer        ; r12 = адрес начала буфера для записи
    xor r8, r8                    ; r8 = начало строки
    xor r13, r13                  ; текущая длина output_buffer
    mov qword [len_output], 0

    .skip_delims:
        cmp r8, [len_input]
        jae .end_check_default

        ; al = строка[r8]
        mov al, [r11 + r8]

        cmp al, SPACE                  ; space
        je .inc_skip
        cmp al, TAB                    ; tab
        je .inc_skip
        cmp al, LF
        je .LFCR_skip
        cmp al, CR
        je .LFCR_skip
        jmp .word_start_found

    .inc_skip:
        inc r8
        jmp .skip_delims

    .LFCR_skip:
        mov [output_buffer + r13], al
        inc r13
        mov [len_output], r13
        inc r8
        jmp .skip_delims

    .word_start_found:
        mov rbx, r8                   ; rbx = начало слова
        mov r9, r8                    ; r9 = конец строки

        .find_delims:
            cmp r9, [len_input]
            jz .border_buffer ; строка закончилась не на пробел, проверить через доп буфер

            ; al = строка[r8]
            mov al, [r11 + r9]

            cmp al, SPACE                  ; space
            je .check_word
            cmp al, TAB                    ; tab
            je .check_word
            cmp al, LF
            je .check_word
            cmp al, CR
            je .check_word

            inc r9
        jmp .find_delims
        
    .check_word:
        mov r10, r9
        dec r9

        .loop_check:
            cmp r8, r9
            jge .is_palindrome

            ; al =строка[r8]
            mov al, [r11 + r8]

            ; dl = строка[r10]
            mov dl, [r11 + r9]

            cmp al, dl
            jne .not_palindrome

            inc r8
            dec r9
        jmp .loop_check

    .border_buffer:
        ;копируем часть слова в входной буфер
        mov rcx, r9
        sub rcx, r8
        mov rax, rcx                   ; сохранить длину

        lea rsi, [r11 + r8] ; от куда
        lea rdi, [r11]      ; куда

        cld                 ; направление копирования - вперед (чистит флаг DF std - наоборот)
        rep movsb           ; копируем строку rsi++ rdi++ rcx--

        mov [len_input], rax

        jmp .finish_check

    .is_palindrome:
        ; rbx = начало слова
        ; r10 = конец слова + 1
        ; r13 = текущее число байт в output_buffer

        inc r10
        mov rcx, r10
        sub rcx, rbx 

        mov rax, OUTPUT_BUF_SIZE
        sub rax, r13                  ; rax = свободно в output_buffer
        cmp rcx, rax
        jbe .copy_whole               ; слово влезает целиком

        cmp r13, 0
        je .check_big_word

        mov qword [len_output], r13
        call write_file
        xor r13, r13
        mov qword [len_output], 0

        .check_big_word:
            ; теперь output_buffer пустой
            cmp rcx, OUTPUT_BUF_SIZE
            ja .while

        .copy_whole:
            ; копируем слово целиком в output_buffer + r13
            mov rax, rcx

            lea rsi, [r11 + rbx]
            lea rdi, [r12 + r13]

            cld
            rep movsb

            add r13, rax
            mov qword [len_output], r13

            ; если буфер заполнился ровно - сразу сбросить в файл
            cmp r13, OUTPUT_BUF_SIZE
            jne .end_while

        .while:
            lea rsi, [r11 + rbx] 

        .copy_chunks:
            cmp rcx, OUTPUT_BUF_SIZE
            jbe .copy_tail                ; остался хвост меньше буфера

            mov rdx, rcx                    
            mov rcx, OUTPUT_BUF_SIZE

            mov rdi, r12                  ; писать с начала output_buffer
            cld
            rep movsb

            mov r13, OUTPUT_BUF_SIZE
            mov qword [len_output], OUTPUT_BUF_SIZE
            call write_file

            xor r13, r13
            mov qword [len_output], 0

            mov rcx, rdx
            sub rcx, OUTPUT_BUF_SIZE
        jmp .copy_chunks

        .copy_tail:
            test rcx, rcx
            jz .end_while

            mov rax, rcx
            mov rdi, r12
            cld
            rep movsb

            mov r13, rax
            mov qword [len_output], r13
            jmp .end_while


        .end_while:
            mov r8, r10
            jmp .skip_delims

    .not_palindrome:
            mov r8, r10
            jmp .skip_delims

    .end_check_default:
        mov qword [len_input], 0

    .finish_check:

        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rcx
        pop rbx
        pop rax

        mov rsp, rbp
        pop rbp
        ret



output_console_message:
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rsi
    push rdx

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, message_file
    mov rdx, msg_len_file
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

input_console_file_name:
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi
    push rsi
    push rdx

    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, file_name
    mov rdx, FILE_NAME_SIZE
    syscall

    test rax, rax
    jle .done

    mov rcx, rax
    dec rcx

    cmp byte [file_name + rcx], LF
    jne .no_lf

    mov byte [file_name + rcx], ZR
    jmp .done

.no_lf:
    cmp rax, 127
    ja .done
    mov byte [file_name + rax], ZR

.done:
    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx

    mov rsp, rbp
    pop rbp
    ret
    

input_console_string:
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi
    push rsi
    push rdx

    mov qword [len_input], 0

    .read_loop:
        mov rsi, input_buffer
        mov rdx, INPUT_BUF_SIZE

        mov rax, [len_input]
        add rsi, rax
        sub rdx, rax

        mov rax, SYS_READ
        mov rdi, STDIN
        syscall

        test rax, rax
        jz .eof
        js error

        add qword [len_input], rax

        call check_palindrome
        cmp qword [len_output], 0
        jz .read_loop

        call write_file

    jmp .read_loop

    .eof:
        cmp qword [len_input], 0
        jz .done

        call check_palindrome
        cmp qword [len_output], 0
        jz .done
        call write_file

    .done:

        mov rax, 1

        pop rdx
        pop rsi
        pop rdi
        pop rcx
        pop r11

        mov rsp, rbp
        pop rbp
        ret

make_file:
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi
    push rsi
    push rdx

    mov rax, SYS_OPEN
    mov rdi, file_name
    mov rsi, O_CREAT | O_TRUNC | O_RDWR 
    mov rdx, 666o
    syscall
    mov [file_descriptor], rax

    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx
    
    mov rsp, rbp
    pop rbp
    ret

close_file: ; в rax - 0 успех, -1 ошибки
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi

    mov rax, SYS_CLOSE
    mov rdi, [file_descriptor]
    syscall

    pop rdi
    pop r11
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

write_file: ; return rax - кол-во записанных байт (-1 в случае ошибки)
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi
    push rsi
    push rdx

    mov rax, SYS_WRITE
    mov rdi, [file_descriptor]
    mov rsi, output_buffer
    mov rdx, [len_output]
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx

    mov rsp, rbp
    pop rbp
    ret

ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

error:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall