extern printf
extern scanf

extern cos
extern log

extern fopen
extern fprintf
extern fclose

extern exit

section .rodata
    input_msg_x db "Enter x: ", 0
    input_msg_a db "Enter a: ", 0
    input_msg_acc db "Enter accuracy: ", 0

    format_in_double db "%lf", 0
    format_out_double db "Res%d: %lf", 10, 0
    format_in_int db "%d", 0

    file_name db "data.txt", 0
    file_mode db "w", 0
    file_fmt  db "n = %d, term = %lf", 10, 0

    one dq 1.0
    two dq -2.0

section .bss
    x        resq 1
    a        resq 1
    accuracy resd 1
    output_1 resq 1
    output_2 resq 1
    file_ptr resq 1

section .text
    global main

main:
    push rbp
    mov rbp, rsp

    call console_inputs
    call right_expression
    call left_expression
    call console_outputs

    mov edi, 0
    call exit


left_expression:
    push rbp
    mov  rbp, rsp



    ; cos α
    movsd xmm0, [rel a]
    call cos
    movsd [rel output_1], xmm0

    ; -2x cos α
    movsd xmm0, [rel x]
    mulsd xmm0, [rel two]
    mulsd xmm0, [rel output_1]
    movsd [rel output_1], xmm0

    ; 1 - 2x cos(a)
    movsd xmm0, [rel one]
    addsd xmm0, [rel output_1]
    movsd [rel output_1], xmm0

    ; 1 − 2x cos α + x^2
    movsd xmm0, [rel x]
    mulsd xmm0, xmm0
    movsd xmm1, [rel output_1]
    addsd xmm1, xmm0
    movsd [rel output_1], xmm1

    ; ln (1 − 2x cos α + x^2) 
    movsd xmm0, [rel output_1]
    call log
    movsd [rel output_1], xmm0

    mov rsp, rbp
    pop rbp
    ret

right_expression:
    push rbp
    mov  rbp, rsp

    call file_open

    mov r8, 1

    .while:
        cmp r8, [rel accuracy]
        je .end_while

        ; cos(nα)
        cvtsi2sd xmm0, r8   ; перекинуть из r8(int) в xmm0(double)
        mulsd xmm0, [rel a]
        push r8
        call cos
        pop r8

        ; x^n
        movsd xmm1, [rel one]   ; result = 1.0
        mov r9, 1
        .pow:
            cmp r9, r8
            jg .end_pow
            mulsd xmm1, [rel x]
            inc r9
            jmp .pow
        .end_pow:

        ; cos(nα) * x^n
        mulsd xmm0, xmm1

        ; n!
        mov r9, 1
        mov r10, 1
        .factorial:
            cmp r9, r8
            jg .end_factorial

            imul r10, r9
            inc r9
        jmp .factorial

        .end_factorial:

        ; cos(nα) * x^n / n!
        cvtsi2sd xmm1, r10
        divsd xmm0, xmm1

        sub rsp, 16
        mov [rsp], r8
        movsd [rsp+8], xmm0 
        call file_write
        mov r8, [rsp]
        movsd xmm0, [rsp+8]
        add rsp, 16

        ; ∑ cos(nα) * x^n / n!
        addsd xmm0, [rel output_2]
        movsd [rel output_2], xmm0

        inc r8
    jmp .while

    .end_while:

    movsd xmm0, [rel output_2]
    mulsd xmm0, [rel two]
    movsd [rel output_2], xmm0

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
    lea rdi, [rel format_in_double]
    lea rsi, [rel x]
    xor eax, eax
    call scanf

    ; printf("Enter a: ")
    lea rdi, [rel input_msg_a]
    xor eax, eax
    call printf

    ; scanf("%lf", &a)
    lea rdi, [rel format_in_double]
    lea rsi, [rel a]
    xor eax, eax
    call scanf

    ; printf("Enter accuracy: ")
    lea rdi, [rel input_msg_acc]
    xor eax, eax
    call printf

    ; scanf("%d", &accuracy)
    lea rdi, [rel format_in_int]
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
    lea rdi, [rel format_out_double]
    mov esi, 1
    movsd xmm0, [rel output_1]
    mov eax, 1
    call printf

    ; printf("Output 2: %lf\n", output_2)
    lea rdi, [rel format_out_double]
    mov esi, 2
    movsd xmm0, [rel output_2]
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