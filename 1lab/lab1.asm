section .rodata
    a dd 1
    b dw -1
    c dd 5
    d dw 4
    e dd 1

section .data
    result dq 0


section .text
    global _start

_start:
    mov  r8d,  dword [a]
    mov  r9w,  word  [b]
    mov  r10d, dword [c]
    mov  r11w, word  [d]
    mov  r12d, dword [e]

    ;(e-b)
    movsxd rax, r12d
    movsx rcx, r9w
    sub rax, rcx
    mov r13, rax

    ;(e+d)
    movsxd rax, r12d
    movsx rcx, r11w
    add rax, rcx
    mov r14, rax

    ;c / (e+d)
    test r14, r14
    jz zero_division

    movsxd rax, r10d
    cqo
    idiv r14
    mov r14, rax

    ;(d+b)
    movsx eax, r11w
    movsx ecx, r9w
    add eax, ecx
    mov r15d, eax

    ;(d+b) / e
    test r12d, r12d
    jz zero_division

    movsxd rax, r15d
    movsxd rcx, r12d
    cqo
    idiv rcx
    mov r15, rax

    ;a * (e-b)
    movsxd rax, r8d
    imul rax, r13
    jo overflow

    ;a*(e-b) * (c/(e+d))
    imul rax, r14
    jo overflow

    ;a*(e-b)*(c/(e+d)) - ((d+b)/e)
    sub rax, r15
    jo overflow

    mov [result], rax

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