.intel_syntax noprefix

.global trim_asm
.extern malloc

# передаем:
# rdi = img
# esi = orig_width
# edx = width
# ecx = height
# r8d = x_start
# r9d = y_start
# возвращаем:
# rax = unsigned char*

trim_asm:
    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 24

    mov rbx, rdi          # img
    movsxd r12, esi       # orig_width
    movsxd r13, edx       # width
    movsxd r14, ecx       # height
    movsxd r15, r8d       # x_start
    mov dword ptr [rbp - 48], r9d   # y_start

    # malloc(width * height * 3)
    mov rax, r13    # rax = width
    imul rax, r14   # rax = width * height
    imul rax, 3     # rax = width * height * 3
    mov rdi, rax    

    call malloc

    test rax, rax
    jz .return_null

    mov qword ptr [rbp - 56], rax   # сохранить result

    # src_start = img + (y_start * orig_width + x_start) * 3

    # y_start * orig_width
    movsxd rax, dword ptr [rbp - 48]    
    imul rax, r12
    add rax, r15                          
    imul rax, 3

    lea r8, [rbx + rax]               

    # ptr res
    mov r9, qword ptr [rbp - 56]

    # src_row_bytes = orig_width * 3
    mov r10, r12
    imul r10, 3

    # dst_row_bytes = width * 3
    mov r11, r13
    imul r11, 3

    xor rcx, rcx        # y = 0

.outer_loop:
    cmp rcx, r14  # столбец
    jge .done

    mov rdi, r8
    mov rsi, r9

    xor rdx, rdx

.inner_loop:
    cmp rdx, r11  # строка
    jge .next_row

    mov al, byte ptr [rdi]
    mov byte ptr [rsi], al

    inc rdi
    inc rsi
    inc rdx

    jmp .inner_loop

.next_row:
    add r8, r10         # orig_width
    add r9, r11         # width

    inc rcx
    jmp .outer_loop

.done:
    mov rax, qword ptr [rbp - 56]
    jmp .finish

.return_null:
    xor rax, rax

.finish:
    add rsp, 24

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret

.section .note.GNU-stack,"",@progbits
