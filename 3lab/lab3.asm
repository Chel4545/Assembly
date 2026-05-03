INPUT_BUF_SIZE  equ 12
OUTPUT_BUF_SIZE equ 20
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

    file_name       resb FILE_NAME_SIZE + 1
    file_descriptor resq 1

    has_output_word resb 1

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

; возвращает:
; rax - длина имени файла
input_console_file_name:
    push rbp
    mov  rbp, rsp

    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push rbx

    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, INPUT_BUF_SIZE
    syscall

    test rax, rax
    js error
    jz error              

    mov [len_input], rax

    lea r11, input_buffer
    xor r8, r8

    mov r10, 1          ; конец буфера считать концом слова
    xor r13, r13        ; LF не записывать в output_buffer

    call get_word

    cmp rax, 1
    jne error

    ; rcx = длина имени файла
    mov rcx, r9
    sub rcx, r8

    ; нет имени файла
    test rcx, rcx
    jz error

    ; вышли за буфер в имени файла
    cmp rcx, FILE_NAME_SIZE
    ja error

    mov r10, rcx        ; сохранить длину имени

    ; записваем имя файла в буфер
    lea rsi, [r11 + r8]
    lea rdi, [file_name]

    cld
    rep movsb

    mov byte [file_name + r10], ZR

    ; перенести хвост после имени файла в начало input_buffer
    mov rdx, [len_input]    
    mov rcx, r9             

    cmp rcx, rdx
    jae .no_tail ;хвоста нет

    inc rcx

    cmp rcx, rdx
    jae .no_tail ;был \n

    mov rbx, rdx
    sub rbx, rcx            ; rbx = длина хвоста

    lea rsi, [input_buffer + rcx]
    lea rdi, [input_buffer]
    mov rcx, rbx

    cld
    rep movsb

    mov [len_input], rbx
    jmp .done

    .no_tail:
        mov qword [len_input], 0

    .done:
        mov rax, r10

        pop rbx
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx

        mov rsp, rbp
        pop rbp
        ret

; принимает:
;   r11 = input_buffer
;   r8  = позиция начала поиска
;   r10 = 0, если EOF ещё не было
;   r10 = 1, если это последний буфер после EOF
;   r13 = 0, не сохранять LF
;   r13 = 1, сохранять LF в output_buffer
;
; возвращает:
;   rax = 0, слов больше нет
;   rax = 1, слово найдено полностью
;   rax = 2, слово началось, но не закончилось в input_buffer
;   r8  = начало слова
;   r9  = конец слова exclusive
get_word:
    push rbp
    mov  rbp, rsp

.skip_delims:
    cmp r8, [len_input]
    jae .not_found

    mov al, [r11 + r8]

    cmp al, SPACE
    je .skip_one
    cmp al, TAB
    je .skip_one
    cmp al, CR
    je .skip_one

    cmp al, LF
    je .skip_lf

    jmp .word_start_found

    .skip_lf:
        test r13, r13
        jz .skip_one ;зач

        call add_lf_to_buffer

    .skip_one:
        inc r8
        jmp .skip_delims

    .word_start_found:
        mov r9, r8

    .find_word_end:
        cmp r9, [len_input]
        jae .end_of_buffer

        mov al, [r11 + r9]

        cmp al, SPACE
        je .found
        cmp al, TAB
        je .found
        cmp al, LF
        je .found
        cmp al, CR
        je .found

        inc r9
        jmp .find_word_end

    .end_of_buffer:
        test r10, r10
        jnz .found   ; зач

        mov rax, 2
        jmp .done

    .found:
        mov rax, 1
        jmp .done

    .not_found:
        xor rax, rax

    .done:
        mov rsp, rbp
        pop rbp
        ret

; соглашение
; принимает r12 = output_buffer, al = символ для записи
; ничего важного не портит

add_char_to_buffer:
    push rbp
    mov  rbp, rsp

    push rbx
    push rax

    cmp qword [len_output], OUTPUT_BUF_SIZE
    jb .store_char

    call write_file
    mov qword [len_output], 0

    .store_char:
        pop rax

        mov rbx, [len_output]
        mov [r12 + rbx], al
        inc qword [len_output]

        pop rbx

        mov rsp, rbp
        pop rbp
        ret

add_space_to_buffer:
    push rbp
    mov  rbp, rsp

    push rax

    mov al, SPACE
    call add_char_to_buffer

    pop rax

    mov rsp, rbp
    pop rbp
    ret

; соглашение
; принимает r12 = output_buffer
; добавляет LF в output_buffer
add_lf_to_buffer:
    push rbp
    mov  rbp, rsp

    push rax

    mov al, LF
    call add_char_to_buffer

    ; после переноса строки следующее слово в строке первое
    mov byte [has_output_word], 0

    pop rax

    mov rsp, rbp
    pop rbp
    ret

; принимает:
;   r11 = input_buffer
;   r8  = начало слова
;   r9  = конец слова exclusive
;
; возвращает:
;   rax = 1, если палиндром
;   rax = 0, если не палиндром
check_palinom:
    push rbp
    mov  rbp, rsp

    push r8
    push r9
    push rdx

    ;слова нет
    cmp r8, r9
    jae .not_palindrome 

    dec r9

    .loop_check:
        cmp r8, r9
        jge .is_palindrome

        mov al, [r11 + r8]
        mov dl, [r11 + r9]

        cmp al, dl
        jne .not_palindrome

        inc r8
        dec r9
    jmp .loop_check

    .is_palindrome:
        mov rax, 1
        jmp .done

    .not_palindrome:
        xor rax, rax
    
    .done:

        pop rdx
        pop r9
        pop r8

        mov rsp, rbp
        pop rbp
        ret  

; принимает:
;   r11 = input_buffer
;   r12 = output_buffer
;   r8  = начало слова
;   r9  = конец слова exclusive
; возвращает:
;   rax = длина остатка слова, который не влез в output_buffer

add_word_to_buffer:
    push rbp
    mov  rbp, rsp

    push rcx
    push rdx
    push rsi
    push rdi
    push rbx

    mov rcx, r9
    sub rcx, r8  ;длина слова

    mov rdx, OUTPUT_BUF_SIZE
    sub rdx, [len_output] ; остаток который запишем

    test rdx, rdx
    jz .no_space

    cmp rcx, rdx
    jbe .copy_whole

    mov rax, rcx
    sub rax, rdx ; длина слова - что сможем записать
    mov rcx, rdx
    jmp .copy

    .copy_whole:
        xor rax, rax        ; остатка нет

    .copy:
        mov rbx, [len_output]
        add [len_output], rcx

        lea rsi, [r11 + r8]
        lea rdi, [r12 + rbx]

        cld
        rep movsb

        jmp .done

    .no_space:
        mov rax, rcx

    .done:
        pop rbx
        pop rdi
        pop rsi
        pop rdx
        pop rcx

        mov rsp, rbp
        pop rbp
        ret
  


output_console_message:
    push rbp
    mov  rbp, rsp

    push rcx
    push r11
    push rdi
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
    
input_console_string:
    push rbp
    mov  rbp, rsp

    push rcx
    push r10
    push r11
    push r12
    push r13
    push rdi
    push rsi
    push rdx
    push r8
    push r9

    .read_loop:
        xor r10, r10

        cmp qword [len_input], 0
        jne .process_buffer

    .read_more:
        mov rsi, input_buffer
        mov rdx, INPUT_BUF_SIZE

        mov rax, [len_input]
        add rsi, rax
        sub rdx, rax

        ; если места нет, значит слово длиннее input_buffer
        test rdx, rdx
        jz error

        mov rax, SYS_READ
        mov rdi, STDIN
        syscall

        test rax, rax
        js error
        jz .eof

        add [len_input], rax

    .process_buffer:
        lea r11, [input_buffer]
        lea r12, [output_buffer]
        xor r8, r8
        mov r13, 1 ; сохранять LF в выходной файл

        jmp .write_loop

    .eof:
        cmp qword [len_input], 0
        jz .finish

        mov r10, 1

        lea r11, [input_buffer]
        lea r12, [output_buffer]
        xor r8, r8
        mov r13, 1

    .write_loop:
        call get_word

        cmp rax, 0
        je .buffer_done

        cmp rax, 2
        je .partial_word

        ; rax = 1, слово найдено полностью
        call check_palinom
        test rax, rax
        jz .next_word

        cmp byte [has_output_word], 0
        je .first_word_in_line

        call add_space_to_buffer

    .first_word_in_line:
        mov byte [has_output_word], 1

    .add_word_loop:
        call add_word_to_buffer

        test rax, rax
        jz .next_word

        push rax
        call write_file
        pop rax

        mov qword [len_output], 0

        mov r8, r9
        sub r8, rax

        jmp .add_word_loop

    .next_word:
        mov r8, r9
        jmp .write_loop

    .partial_word: ; перенос слова на границе буфера

        mov rcx, [len_input]
        sub rcx, r8             ; rcx = длина неполного слова

        ; слово занимает весь буфер
        cmp rcx, INPUT_BUF_SIZE
        jae error

        mov rdx, rcx            ; сохранить длину слова

        lea rsi, [input_buffer + r8]
        lea rdi, [input_buffer]

        cld
        rep movsb

        mov [len_input], rdx

        jmp .read_more

    .buffer_done:
        mov qword [len_input], 0

        test r10, r10
        jnz .finish

        jmp .read_loop

    .finish:
        cmp qword [len_output], 0
        je .done

        call write_file

    .done:
        mov rax, 1

        pop r9
        pop r8
        pop rdx
        pop rsi
        pop rdi
        pop r13
        pop r12
        pop r11
        pop r10
        pop rcx

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

    test rax, rax
    js error
    
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

    test rax, rax
    js error

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