extern printf
extern scanf

extern cosf
extern logf
extern fabsf

extern fopen
extern fprintf
extern fclose

extern exit

section .rodata
    ; ввод файла при запуске
    input_msg_x db "Enter x: ", 0
    input_msg_a db "Enter a: ", 0
    input_msg_acc db "Enter accuracy: ", 0

    no_file_name_msg db "Error: no file name", 10, 0
    open_file_error_msg db "Error: couldn't open the file", 10, 0
    close_file_error_msg db "Error: couldn't close the file", 10, 0
    write_file_error_msg db "Error: couldn't write the file", 10, 0
    input_error_msg db "Error: invalid input", 10, 0
    x_range_error_msg db "Error: mod(x) must be <= 1", 10, 0
    acc_error_msg db "Error: accuracy must be > 0", 10, 0
    log_error_msg db "Error: logarithm argument must be > 0", 10, 0

    format_in_float db "%f", 0
    format_skip_token db "%*s", 0
    format_out_float db "Res%d: %f", 10, 0

    file_mode db "w", 0
    file_fmt  db "n = %d, term = %f", 10, 0

    minus_one dd -1.0
    one       dd  1.0
    two       dd  2.0
    minus_two dd -2.0

section .text
    global main

main:
    ;rdi = argc
    ;rsi = argv
    push rbp
    mov rbp, rsp 
    sub rsp, 32


    ; получаем имя файла
    call get_file_name
    mov [rbp - 8], rax


    ; получаем x
    .write_x:
    lea rdi, [rel input_msg_x]
    call read_float
    
    ; проверка х
    ucomiss xmm0, [rel one]
    ja .x_range_error
    ucomiss xmm0, [rel minus_one]
    jb .x_range_error

    ; запись x
    movss [rbp - 12], xmm0


    ; получаем a
    lea rdi, [rel input_msg_a]
    call read_float

    ; запись a
    movss [rbp - 16], xmm0


    ; получаем accuracy
    .write_acc:
    lea rdi, [rel input_msg_acc]
    call read_float

    ; проверяем accuracy
    xorps xmm1, xmm1
    ucomiss xmm0, xmm1
    jbe .acc_error

    ; запись x
    movss [rbp - 20], xmm0


    movss xmm0, [rbp - 12]
    movss xmm1, [rbp - 16]
    call left_expression
    movss [rbp - 24], xmm0 ; output_1

    movss xmm0, [rbp - 12]
    movss xmm1, [rbp - 16]
    movss xmm2, [rbp - 20]
    movss xmm3, [rbp - 24]
    mov   rax , [rbp - 8]
    call right_expression
    movss [rbp - 28], xmm0 ; output_2

    ; вывод output_1
    lea rdi, [rel format_out_float]
    mov esi, 1
    cvtss2sd xmm0, [rbp - 24]
    mov eax, 1
    call printf

    ; вывод output_2
    lea rdi, [rel format_out_float]
    mov esi, 2
    cvtss2sd xmm0, [rbp - 28]
    mov eax, 1
    call printf

    mov edi, 0
    call exit

    .x_range_error:
        lea rdi, [rel x_range_error_msg]
        xor eax, eax
        call printf

        jmp .write_x

    .acc_error:
        lea rdi, [rel acc_error_msg]
        xor eax, eax
        call printf

        jmp .write_acc

; возхвращает rax = file_name
get_file_name:
    push rbp
    mov  rbp, rsp

    cmp rdi, 2
    jne .bad_args

    mov rax, [rsi + 8]

    mov rsp, rbp
    pop rbp
    ret

    .bad_args:
        lea rdi, [rel no_file_name_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

; параметры: xmm0 = x
;            xmm1 = a
; возврат:   xmm0 = output_1
left_expression:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16

    ; заносим данные в стек
    movss [rbp - 4],  xmm0 ; x
    movss [rbp - 8],  xmm1 ; a

    ; cosf α
    movss xmm0, [rbp - 8]
    call cosf

    ; -2x cosf α
    movss xmm1, [rbp - 4]
    mulss xmm1, [rel minus_two]
    mulss xmm0, xmm1

    ; 1 - 2x cosf(a)
    addss xmm0, [rel one]

    ; 1 − 2x cosf α + x^2
    movss xmm1, [rbp - 4]
    mulss xmm1, xmm1
    addss xmm0, xmm1

    ; проверка на ln(0)
    xorps xmm1, xmm1
    ucomiss xmm0, xmm1
    jp .log_error
    jbe .log_error

    ; ln (1 − 2x cosf α + x^2)
    ; добавить проверку на x = 1 и a = 0
    call logf

    mov rsp, rbp
    pop rbp
    ret

    .log_error:
        lea rdi, [rel log_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

; параметры: xmm0 = x
;            xmm1 = a
;            xmm2 = accuracy
;            xmm3 = output_1
;            rax  = file
; возврат:   xmm0 = output_2
right_expression:
    push rbp
    mov  rbp, rsp

    sub rsp, 64

    push r12
    sub rsp, 8

    movss [rbp - 4],  xmm0 ; x
    movss [rbp - 8],  xmm1 ; a
    movss [rbp - 12], xmm2 ; accuracy
    movss [rbp - 16], xmm3 ; output_1
    xorps xmm0, xmm0
    movss [rbp - 20], xmm0 ; output_2

    ; открываем файл
    mov rdi, rax
    lea rsi, [rel file_mode]
    call file_open
    mov [rbp - 28], rax     ; file_ptr

    ; подготовка степени
    movss xmm0, [rel one]
    movss [rbp - 32], xmm0

    ; подготовка косинуса
    ; cos((n + 1)a) = 2 * cos(a) * cos(na) - cos((n - 1)a)
    movss xmm0, [rel one]
    movss [rbp - 36], xmm0 ; cos_prev
    movss xmm0, [rbp - 8]
    call cosf
    movss [rbp - 40], xmm0      ; cos_a
    movss [rbp - 44], xmm0      ; cos_curr

    mov r12, 1
    .while:
        movss xmm0, [rbp - 20]
        mulss xmm0, [rel minus_two]
        subss xmm0, [rbp - 16]
        call fabsf
        ucomiss xmm0, [rbp - 12]
        jbe .end_while

        ; x^n
        movss xmm1, [rbp - 32]  ; x_power
        mulss xmm1, [rbp - 4]   ; x
        movss [rbp - 32], xmm1

        ; cosf(nα) * x^n
        movss xmm0, [rbp - 44]  ; cos_curr
        mulss xmm0, xmm1

        ; cosf(nα) * x^n / n
        cvtsi2ss xmm1, r12
        divss xmm0, xmm1

        movss [rbp - 48], xmm0
        mov rdi, [rbp - 28]
        lea rsi, [rel file_fmt]
        mov rdx, r12
        call file_write
        movss xmm0, [rbp - 48]

        ; ∑ cosf(nα) * x^n / n
        addss xmm0, [rbp - 20]
        movss [rbp - 20], xmm0

        ; обновляем cos:
        ; cos_next = 2 * cos_a * cos_curr - cos_prev
        movss xmm0, [rbp - 40]
        mulss xmm0, [rel two]
        mulss xmm0, [rbp - 44]
        subss xmm0, [rbp - 36]

        ; cos_prev = cos_curr
        movss xmm1, [rbp - 44]
        movss [rbp - 36], xmm1

        ; cos_curr = cos_next
        movss [rbp - 44], xmm0

        inc r12
    jmp .while

    .end_while:

    mov rdi, [rbp - 28]
    call file_close

    movss xmm0, [rbp - 20]
    mulss xmm0, [rel minus_two]

    add rsp, 8
    pop r12

    mov rsp, rbp
    pop rbp
    ret

; параметры: rdi = prompt
; возврат:  xmm0 = input
read_float:
    push rbp
    mov  rbp, rsp
    sub rsp, 16

    mov [rbp - 8], rdi

    ; printf(prompt)
    .write:
    xor eax, eax
    call printf

    ; scanf("%f", &local_float)
    lea rdi, [rel format_in_float]
    lea rsi, [rbp - 12]
    xor eax, eax
    call scanf

    cmp eax, 0
    je .input_error
    jl .input_eof

    movss xmm0, [rbp - 12]

    mov rsp, rbp
    pop rbp
    ret

    .input_error:
        lea rdi, [rel input_error_msg]
        xor eax, eax
        call printf

        ; удалить неправильный токен из stdin
        lea rdi, [rel format_skip_token]
        xor eax, eax
        call scanf

        mov rdi, [rbp - 8]

        jmp .write
    
    .input_eof:
        mov edi, 1
        call exit


; параметры: rdi = file_name
;            rsi = file_mode
; возврат:   rax = file_ptr
file_open:
    push rbp
    mov  rbp, rsp

    ; FILE *file = fopen("output.txt", "w");
    call fopen
    test rax, rax
    jz .file_open_error

    mov rsp, rbp
    pop rbp
    ret

    .file_open_error:
        lea rdi, [rel open_file_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit


; параметры: rdi  = file_ptr
;            rsi  = file_fmt
;            rdx  = n
;            xmm0 = term 
file_write:
    push rbp
    mov  rbp, rsp

    ; fprintf(file, "n = %d, term = %f\n", n, term);
    cvtss2sd xmm0, xmm0
    mov eax, 1
    call fprintf

    cmp eax, 0
    jl .write_error

    mov rsp, rbp
    pop rbp
    ret

    .write_error:
        lea rdi, [rel write_file_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit


; параметры: rdi = file_ptr
file_close:
    push rbp
    mov  rbp, rsp

    call fclose

    cmp eax, 0
    jne .close_error

    mov rsp, rbp
    pop rbp
    ret

    .close_error:
        lea rdi, [rel close_file_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit