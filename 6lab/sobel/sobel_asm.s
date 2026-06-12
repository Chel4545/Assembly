.intel_syntax noprefix

.global sobel_asm

# передаем:
# rdi = img
# rsi = result
# edx = width
# ecx = height
#
# возвращаем:
# eax = 0/-1(успех/ошибка)

sobel_asm:
    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 72             



    mov r12, rdi   # r12 = img
    mov r13, rsi   # r13 = result
    mov r14d, edx  # r14d = width
    mov r15d, ecx  # r15d = height
    mov ebx, r14d
    dec ebx        # ebx = width - 1
    mov edx, r15d
    dec edx        # edx = height - 1

    xor eax, eax   # eax = 0



    # if (img == NULL)
    test r12, r12
    jz .return_error

    # if (result == NULL)
    test r13, r13
    jz .return_error

    # if (width <= 0)
    cmp r14d, 0
    jle .return_error

    # if (height <= 0)
    cmp r15d, 0
    jle .return_error

    # if (width < 3)
    cmp r14d, 3
    jl .return_success

    # if (height < 3)
    cmp r15d, 3
    jl .return_success



    mov r8d, 1 # y = 1
    .outer_loop:
        cmp r8d, edx
        jge .return_success

        mov r9d, 1 # x = 1
        .inner_loop:
            cmp r9d, ebx
            jge .next_row



            # (y - 1) * width + x
            mov eax, r8d        # eax = y
            dec eax             # eax = y - 1
            imul eax, r14d      # eax = (y - 1) * width
            add eax, r9d        # eax = (y - 1) * width + x
            movsxd rax, eax
            mov qword ptr [rsp + 0], rax

            # y * width + x
            mov eax, r8d        # eax = y
            imul eax, r14d      # eax = y * width
            add eax, r9d        # eax = y * width + x
            movsxd rax, eax
            mov qword ptr [rsp + 8], rax

            # (y + 1) * width + x
            mov eax, r8d        # eax = y
            inc eax             # eax = y + 1
            imul eax, r14d      # eax = (y + 1) * width
            add eax, r9d        # eax = (y + 1) * width + x
            movsxd rax, eax
            mov qword ptr [rsp + 16], rax



            # a = img[(y - 1) * width + (x - 1)]
            mov r10, qword ptr [rsp + 0]
            movzx eax, byte ptr [r12 + r10 - 1]
            mov dword ptr [rsp + 24], eax

            # b = img[(y - 1) * width + x]
            mov r10, qword ptr [rsp + 0]
            movzx eax, byte ptr [r12 + r10]
            mov dword ptr [rsp + 28], eax

            # c = img[(y - 1) * width + (x + 1)]
            mov r10, qword ptr [rsp + 0]
            movzx eax, byte ptr [r12 + r10 + 1]
            mov dword ptr [rsp + 32], eax

            # d = img[y * width + (x - 1)]
            mov r10, qword ptr [rsp + 8]
            movzx eax, byte ptr [r12 + r10 - 1]
            mov dword ptr [rsp + 36], eax

            # f = img[y * width + (x + 1)]
            mov r10, qword ptr [rsp + 8]
            movzx eax, byte ptr [r12 + r10 + 1]
            mov dword ptr [rsp + 40], eax

            # g = img[(y + 1) * width + (x - 1)]
            mov r10, qword ptr [rsp + 16]
            movzx eax, byte ptr [r12 + r10 - 1]
            mov dword ptr [rsp + 44], eax

            # h = img[(y + 1) * width + x]
            mov r10, qword ptr [rsp + 16]
            movzx eax, byte ptr [r12 + r10]
            mov dword ptr [rsp + 48], eax

            # i = img[(y + 1) * width + (x + 1)]
            mov r10, qword ptr [rsp + 16]
            movzx eax, byte ptr [r12 + r10 + 1]
            mov dword ptr [rsp + 52], eax



            # gx = c - a - 2*d + 2*f - g + i
            mov eax, dword ptr [rsp + 32]   # eax = c
            sub eax, dword ptr [rsp + 24]   # eax = c - a

            mov r10d, dword ptr [rsp + 36]  # r10d = d
            add r10d, r10d                  # r10d = 2*d
            sub eax, r10d                   # eax = c - a - 2*d

            mov r10d, dword ptr [rsp + 40]  # r10d = f
            add r10d, r10d                  # r10d = 2*f
            add eax, r10d                   # eax = c - a - 2*d + 2*f

            sub eax, dword ptr [rsp + 44]   # eax = c - a - 2*d + 2*f - g
            add eax, dword ptr [rsp + 52]   # eax = c - a - 2*d + 2*f -g + i

            mov dword ptr [rsp + 56], eax

            # gy = g + 2*h + i - a - 2*b - c
            mov eax, dword ptr [rsp + 44]   # eax = g

            mov r10d, dword ptr [rsp + 48]  # r10d = h
            add r10d, r10d                  # r10d = 2*h
            add eax, r10d                   # eax = g + 2*h

            add eax, dword ptr [rsp + 52]   # eax = g + 2*h + i

            sub eax, dword ptr [rsp + 24]   # eax = g + 2*h + i - a

            mov r10d, dword ptr [rsp + 28]  # r10d = b
            add r10d, r10d                  # r10d = 2*b
            sub eax, r10d                   # eax = g + 2*h + i - a - 2*b

            sub eax, dword ptr [rsp + 32]   # eax = g + 2*h + i - a - 2*b - c
            
            mov dword ptr [rsp + 60], eax 



            # value = abs(gx) + abs(gy)
            mov eax, dword ptr [rsp + 56]
            mov r10d, dword ptr [rsp + 60]

            # abs(gx)
            cmp eax, 0
            jge .gx_abs_done
            neg eax
            .gx_abs_done:

            # abs(gy)
            cmp r10d, 0
            jge .gy_abs_done
            neg r10d
            .gy_abs_done:

            add eax, r10d



            # if (value > 255) value = 255
            cmp eax, 255
            jle .value_ok
            mov eax, 255


            .value_ok:
            # result[y * width + x] = (unsigned char)value
            mov r10, qword ptr [rsp + 8]    # r10 = y * width + x
            mov byte ptr [r13 + r10], al    # result[index] = value

            inc r9d

        jmp .inner_loop

    .next_row:
        inc r8d      
        jmp .outer_loop

    jmp .return_success


.return_success:
    xor eax, eax  # eax = 0
    jmp .finish

.return_error:
    mov eax, -1   # eax = -1
    jmp .finish

.finish:
    add rsp, 72

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret

.section .note.GNU-stack,"",@progbits
