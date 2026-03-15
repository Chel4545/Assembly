section .rodata
    a dd 1
    b dw 0
    c dd 100000
    d dw -32766
    e dd 32767

section .data
    result dq 0


section .text
    global _start

_start:
    mov   r8d,       [a]
    movsx r9d,  word [b]
    mov   r10d,      [c]
    movsx r11d, word [d]
    mov   r12d,      [e]

    ;(e-b)
    movsx r12, r12d
    movsx r9, r9d
    sub r12, r9
    mov r13, r12
;Komar_sosy

    ;(e+d)
    movsx r12, r12d
    movsx r11, r11d
    add r12, r11
    mov r14, r12

    ;(d+b)
    mov r15d, r9d
    add r15d, r11d

    
    ;(d+b) / e
    movsx rax, r15d
    movsx r12, r12d
    ;mov ecx, r12d

    test r12, r12 ; and побитово без записи как в xor
    jz zero_division

    cdq
    idiv rax
    mov r12, rax

    ; с / (e+d)
    mov eax, r10d
    mov ecx, r14d

    test ecx, ecx 
    jz zero_division

    cdq;для расширени
    idiv ecx
    mov r14d, eax

    ;(e-b) * c/(e+d)
    mov eax, r13d
    mov ecx, r14d
    imul eax, ecx
    jo overflow
    mov r14d, eax

    ;a * (e-b)*c/(e+d)
    mov eax, r8d
    mov ecx, r14d
    imul eax, ecx
    jo overflow
    mov r14d, eax

    ;a*(e-b)*c/(e+d) - (d+b)/e
    mov eax, r14d
    mov ecx, r12d
    sub eax, ecx
    jo overflow 
    mov r12d, eax

    mov [result], r12d

    jmp ok


;системные вызовы для выхода
ok:
    mov rax, 60
    xor rdi, rdi
    syscall

overflow:
    mov rax, 60 
    mov rdi, 2 
    syscall 

zero_division:;
    mov rax, 60 
    mov rdi, 1
    syscall  