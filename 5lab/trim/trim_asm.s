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

    # malloc(width * height * 3)
    movsxd rax, r13d    # rax = width
    movsxd r10, r14d    # r10 = height
    imul rax, r10       # rax = width * height
    lea rdi, [rax + rax * 2]    # rdi = width * height * 3

    call malloc

    test rax, rax
    jz .return_null

    mov qword ptr [rbp - 56], rax   # сохранить result

    # src_start = img + ((y_start * orig_width + x_start) * 3)
    movsxd rax, dword ptr [rbp - 48]    
    movsxd r10, r12d                   
    imul rax, r10                       

    movsxd r10, r15d                    
    add rax, r10    

    lea rax, [rax + rax * 2]            
    lea r8, [rbx + rax]               

    mov r9, qword ptr [rbp - 56]

    # src_row_bytes = orig_width * 3
    movsxd r10, r12d
    lea r10, [r10 + r10 * 2]

    # dst_row_bytes = width * 3
    movsxd r11, r13d
    lea r11, [r11 + r11 * 2]

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

    # result[dst_index + 0] = img[src_index + 0]
    mov al, byte ptr [rdi]
    mov byte ptr [rsi], al

    # result[dst_index + 1] = img[src_index + 1]
    mov al, byte ptr [rdi + 1]
    mov byte ptr [rsi + 1], al

    # result[dst_index + 2] = img[src_index + 2]
    mov al, byte ptr [rdi + 2]
    mov byte ptr [rsi + 2], al

    add rdi, 3
    add rsi, 3

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
