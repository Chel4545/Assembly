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

    format_in_float db "%f", 0
    format_out_float db "Res%d: %f", 10, 0
    format_in_int db "%d", 0

    file_name db "data.txt", 0
    file_mode db "w", 0
    file_fmt  db "n = %d, term = %f", 10, 0

    one dd 1.0
    two dd -2.0

section .bss
    x        resd 1
    a        resd 1
    accuracy resd 1
    output_1 resd 1
    output_2 resd 1
    file_ptr resd 1

section .text
    global main

main:
    push rbp
    mov rbp, rsp

    call console_inputs
    call left_expression
    call right_expression
    call console_outputs

    mov edi, 0
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

    movss xmm2, [rel output_1] ; output_2 = 0.0
    divss xmm2, [rel accuracy]
    cvttss2si r10, xmm2

    xorps xmm0, xmm0
    movss [rel output_2], xmm0

    mov r8, 1
    .while:
        movss xmm0, [rel output_2]
        mulss xmm0, [rel two] 
        divss xmm0, [rel accuracy]
        cvttss2si r11, xmm0
        push r10
        push r11
        
        cmp r11, r10
        je .end_while

        ; cosf(nα)
        cvtsi2ss xmm0, r8   ; перекинуть из r8(int) в xmm0(double)
        mulss xmm0, [rel a]
        push r8
        call cosf
        pop r8

        ; x^n
        movss xmm1, [rel one]   ; result = 1.0
        mov r9, 1
        ; тут сделать через x^n-1 в xmm2
        .pow:
            cmp r9, r8
            jg .end_pow
            mulss xmm1, [rel x]
            inc r9
            jmp .pow
        .end_pow:

        ; cosf(nα) * x^n
        mulss xmm0, xmm1

        ; cosf(nα) * x^n / n
        cvtsi2ss xmm1, r8
        divss xmm0, xmm1

        sub rsp, 16
        mov [rsp], r8
        movss [rsp+8], xmm0 
        call file_write
        mov r8, [rsp]
        movss xmm0, [rsp+8]
        add rsp, 16

        ; ∑ cosf(nα) * x^n / n!
        addss xmm0, [rel output_2]
        movss [rel output_2], xmm0

        inc r8
        pop r11
        pop r10
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

    ; printf("Enter a: ")
    lea rdi, [rel input_msg_a]
    xor eax, eax
    call printf

    ; scanf("%lf", &a)
    lea rdi, [rel format_in_float]
    lea rsi, [rel a]
    xor eax, eax
    call scanf

    ; printf("Enter accuracy: ")
    lea rdi, [rel input_msg_acc]
    xor eax, eax
    call printf

    ; scanf("%d", &accuracy)
    lea rdi, [rel format_in_float]
    lea rsi, [rel accuracy]
    xor eax, eax
    call scanf

    mov rsp, rbp
    pop rbp
    ret

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
    lea rdi, [rel file_name]
    lea rsi, [rel file_mode]
    call fopen
    test rax, rax
    jz .file_open_error

    mov [rel file_ptr], rax
    jmp .file_open_success

    .file_open_error:
        xor eax, eax
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