extern printf
extern scanf

extern cosf
extern logf

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
    input_error_msg db "Error: invalid input", 10, 0
    x_range_error_msg db "Error: mod(x) must be <= 1", 10, 0
    acc_error_msg db "Error: accuracy must be > 0", 10, 0

    format_in_float db "%f", 0
    format_out_float db "Res%d: %f", 10, 0

    file_mode db "w", 0
    file_fmt  db "n = %d, term = %f", 10, 0

    minus_one dd -1.0
    one       dd 1.0
    two       dd -2.0

section .bss
    x         resd 1
    a         resd 1
    accuracy  resd 1
    output_1  resd 1
    output_2  resd 1
    file_name resq 1
    file_ptr  resq 1
    x_power   resd 1

section .text
    global main

main:
    ;rdi = argc
    ;rsi = argv
    push rbp
    mov rbp, rsp

    call get_file_name
    call console_inputs
    call left_expression
    call right_expression
    call console_outputs

    mov edi, 0
    call exit


get_file_name:
    push rbp
    mov  rbp, rsp

    cmp rdi, 2
    jne .bad_args

    mov rax, [rsi + 8]
    mov [rel file_name], rax

    mov rsp, rbp
    pop rbp
    ret

    .bad_args:
        lea rdi, [rel no_file_name_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

left_expression:
    push rbp
    mov  rbp, rsp

    ; cosf α
    movss xmm0, [rel a]
    call cosf
    movss [rel output_1], xmm0

    ; -2x cosf α
    movss xmm0, [rel x]
    mulss xmm0, [rel two]
    mulss xmm0, [rel output_1]
    movss [rel output_1], xmm0

    ; 1 - 2x cosf(a)
    movss xmm0, [rel one]
    addss xmm0, [rel output_1]
    movss [rel output_1], xmm0

    ; 1 − 2x cosf α + x^2
    movss xmm0, [rel x]
    mulss xmm0, xmm0
    movss xmm1, [rel output_1]
    addss xmm1, xmm0
    movss [rel output_1], xmm1

    ; ln (1 − 2x cosf α + x^2) 
    movss xmm0, [rel output_1]
    call logf
    movss [rel output_1], xmm0

    mov rsp, rbp
    pop rbp
    ret

right_expression:
    push rbp
    mov  rbp, rsp

    call file_open

    movss xmm0, [rel one]
    movss [rel x_power], xmm0

    mov r8, 1
    .while:
        movss xmm0, [rel output_2]
        mulss xmm0, [rel two] 
        subss xmm0, [rel output_1]
        ucomiss xmm0, [rel accuracy] 
        ja .continue_while

        xorps xmm1, xmm1
        subss xmm1, [rel accuracy]
        ucomiss xmm0, xmm1
        jb .continue_while

        jmp .end_while
        
        .continue_while:
            ; cosf(nα)
            cvtsi2ss xmm0, r8   ; перекинуть из r8(int) в xmm0(double)
            mulss xmm0, [rel a]
            sub rsp, 16
            mov [rsp], r8
            mov [rsp+8], r10
            call cosf
            mov r8, [rsp]
            mov r10, [rsp+8]
            add rsp, 16

            ; x^n
            movss xmm2, [rel x_power]
            mulss xmm2, [rel x]
            movss [rel x_power], xmm2

            ; cosf(nα) * x^n
            mulss xmm0, xmm2

            ; cosf(nα) * x^n / n
            cvtsi2ss xmm1, r8
            divss xmm0, xmm1

            sub rsp, 32
            mov [rsp], r8
            mov [rsp+8], r10
            movss [rsp+16], xmm0
            call file_write
            mov r8, [rsp]
            mov r10, [rsp+8]
            movss xmm0, [rsp+16]
            add rsp, 32

            ; ∑ cosf(nα) * x^n / n!
            addss xmm0, [rel output_2]
            movss [rel output_2], xmm0

            inc r8
    jmp .while

    .end_while:

    movss xmm0, [rel output_2]
    mulss xmm0, [rel two]
    movss [rel output_2], xmm0

    call file_close

    mov rsp, rbp
    pop rbp
    ret

console_inputs:
    push rbp
    mov  rbp, rsp

    ; printf("Enter x: ")
    lea rdi, [rel input_msg_x]
    xor eax, eax
    call printf

    ; scanf("%lf", &x)
    lea rdi, [rel format_in_float]
    lea rsi, [rel x]
    xor eax, eax
    call scanf

    cmp eax, 1
    jne .input_error

    movss xmm0, [rel x]
    ucomiss xmm0, [rel one]
    jp .x_range_error        ; nan
    ja .x_range_error        

    ucomiss xmm0, [rel minus_one]
    jp .x_range_error        
    jb .x_range_error  

    ; printf("Enter a: ")
    lea rdi, [rel input_msg_a]
    xor eax, eax
    call printf

    ; scanf("%lf", &a)
    lea rdi, [rel format_in_float]
    lea rsi, [rel a]
    xor eax, eax
    call scanf

    cmp eax, 1
    jne .input_error

    ; printf("Enter accuracy: ")
    lea rdi, [rel input_msg_acc]
    xor eax, eax
    call printf

    ; scanf("%d", &accuracy)
    lea rdi, [rel format_in_float]
    lea rsi, [rel accuracy]
    xor eax, eax
    call scanf

    cmp eax, 1
    jne .input_error

    movss xmm0, [rel accuracy]
    xorps xmm1, xmm1          
    ucomiss xmm0, xmm1
    jp .acc_error            
    jbe .acc_error

    mov rsp, rbp
    pop rbp
    ret

    .input_error:
        lea rdi, [rel input_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

    .x_range_error:
        lea rdi, [rel x_range_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

    .acc_error:
        lea rdi, [rel acc_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

console_outputs:
    push rbp
    mov  rbp, rsp

    ; printf("Output 1: %lf\n", output_1)
    lea rdi, [rel format_out_float]
    mov esi, 1
    cvtss2sd xmm0, [rel output_1]
    mov eax, 1
    call printf

    ; printf("Output 2: %lf\n", output_2)
    lea rdi, [rel format_out_float]
    mov esi, 2
    cvtss2sd xmm0, [rel output_2]
    mov eax, 1
    call printf

    mov rsp, rbp
    pop rbp
    ret  

file_open:
    push rbp
    mov  rbp, rsp

    ; FILE *file = fopen("output.txt", "w");
    mov rdi, [rel file_name]
    lea rsi, [rel file_mode]
    call fopen
    test rax, rax
    jz .file_open_error

    mov [rel file_ptr], rax
    jmp .file_open_success

    .file_open_error:
        lea rdi, [rel open_file_error_msg]
        xor eax, eax
        call printf

        mov edi, 1
        call exit

    .file_open_success:
        mov rsp, rbp
        pop rbp
        ret

file_write: ; xmm0 - term, r8 - n
    push rbp
    mov  rbp, rsp

    ; fprintf(file, "n = %d, term = %lf\n", n, term);
    mov rdi, [rel file_ptr]
    lea rsi, [rel file_fmt]
    mov rdx, r8
    mov eax, 1
    call fprintf

    mov rsp, rbp
    pop rbp
    ret

file_close:
    push rbp
    mov  rbp, rsp

    mov rdi, [rel file_ptr]
    call fclose

    mov rsp, rbp
    pop rbp
    ret

