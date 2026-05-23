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

    mov rbx, rdi        # img
    mov r12d, esi       # orig_width
    mov r13d, edx       # width
    mov r14d, ecx       # height
    mov r15d, r8d       # x_start
    mov dword ptr [rbp - 48], r9d   # y_start

    # malloc(width * height)
    movsxd rax, r13d    # rax = width
    movsxd r10, r14d    # r10 = height
    imul rax, r10       # rax = width * height
    mov rdi, rax    # rdi = width * height * 3

    call malloc

    test rax, rax
    jz .return_null

    mov qword ptr [rbp - 56], rax   # сохранить result

    # src_start = img + (y_start * orig_width + x_start)

    # y_start * orig_width
    movsxd rax, dword ptr [rbp - 48]    
    movsxd r10, r12d                 
    imul rax, r10                       

    # + x_start
    movsxd r10, r15d                    
    add rax, r10    

    lea r8, [rbx + rax]               

    # ptr res
    mov r9, qword ptr [rbp - 56]

    # src_row_bytes = orig_width
    movsxd r10, r12d

    # dst_row_bytes = width * 3
    movsxd r11, r13d

    xor ecx, ecx        # y = 0

.outer_loop:
    cmp ecx, r14d  # столбец
    jge .done

    mov rdi, r8
    mov rsi, r9

    xor edx, edx

.inner_loop:
    cmp edx, r13d  # строка
    jge .next_row

    mov al, byte ptr [rdi]
    mov byte ptr [rsi], al

    inc rdi
    inc rsi

    inc edx
    jmp .inner_loop

.next_row:
    add r8, r10         # orig_width * 3
    add r9, r11         # width * 3

    inc ecx
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
