.intel_syntax noprefix

.global sobel_asm_vector

# передаем:
# rdi = img
# rsi = result
# edx = width
# ecx = height
#
# возвращаем:
# eax = 0/-1(успех/ошибка)

sobel_asm_vector:
    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 16           



    mov r12, rdi   # r12 = img
    mov r13, rsi   # r13 = result
    mov r14d, edx  # r14d = width
    mov r15d, ecx  # r15d = height
    mov ebx, r14d
    dec ebx        # edx = width - 1
    mov edx, r15d
    dec edx        # ebx = height - 1

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



    #(width - 2) % 8
    mov eax, r14d
    sub eax, 2 
    and eax, 7 

    # (width - 1) - скалярный остаток
    mov r11d, ebx
    sub r11d, eax



    mov r8d, 1 # y = 1
    .outer_loop:
        cmp r8d, edx
        jge .return_success

        # (y - 1) * width
        mov eax, r8d
        dec eax
        imul eax, r14d
        movsxd rax, eax
        lea rdi, [r12 + rax]       # rdi = top

        # y * width
        mov eax, r8d
        imul eax, r14d
        movsxd rax, eax
        lea rsi, [r12 + rax]       # rsi = mid
        lea r10, [r13 + rax]       # r10 = dst

        # (y + 1) * width
        mov eax, r8d
        inc eax
        imul eax, r14d
        movsxd rax, eax
        lea rcx, [r12 + rax]       # rcx = bot

        mov r9d, 1 # x = 1
        .vector_loop:
            cmp r9d, r11d
            jge .scalar_tail



            pxor xmm0, xmm0

            movq xmm1, qword ptr [rdi + r9 - 1]    # xmm1 = A
            punpcklbw xmm1, xmm0                   

            movq xmm2, qword ptr [rdi + r9]        # xmm2 = B
            punpcklbw xmm2, xmm0                   

            movq xmm3, qword ptr [rdi + r9 + 1]    # xmm3 = C
            punpcklbw xmm3, xmm0                   

            movq xmm4, qword ptr [rsi + r9 - 1]    # xmm4 = D
            punpcklbw xmm4, xmm0                   

            movq xmm5, qword ptr [rsi + r9 + 1]    # xmm5 = F
            punpcklbw xmm5, xmm0                   

            movq xmm6, qword ptr [rcx + r9 - 1]    # xmm6 = G
            punpcklbw xmm6, xmm0                   

            movq xmm7, qword ptr [rcx + r9]        # xmm7 = H
            punpcklbw xmm7, xmm0                  

            movq xmm8, qword ptr [rcx + r9 + 1]    # xmm8 = I
            punpcklbw xmm8, xmm0      



            #GX = (C + 2*F + I) - (A + 2*D + G)
            
            # xmm9 = C + 2*F + I
            movdqa xmm9, xmm3

            movdqa xmm10, xmm5
            psllw xmm10, 1 
            paddw xmm9, xmm10

            paddw xmm9, xmm8
        
            # xmm10 = A + 2*D + G
            movdqa xmm10, xmm1

            movdqa xmm11, xmm4
            psllw xmm11, 1  
            paddw xmm10, xmm11

            paddw xmm10, xmm6

            # xmm9 = GX
            psubw xmm9, xmm10


            # GY = (G + 2*H + I) - (A + 2*B + C)

            # xmm10 = G + 2*H + I
            movdqa xmm10, xmm6

            movdqa xmm11, xmm7
            psllw xmm11, 1
            paddw xmm10, xmm11

            paddw xmm10, xmm8

            # xmm11 = A + 2*B + C
            movdqa xmm11, xmm1 

            movdqa xmm12, xmm2
            psllw xmm12, 1
            paddw xmm11, xmm12 

            paddw xmm11, xmm3

            # xmm10 = GY
            psubw xmm10, xmm11



            # abs(GX)
            movdqa xmm11, xmm0
            pcmpgtw xmm11, xmm9

            pxor xmm9, xmm11
            psubw xmm9, xmm11

            # abs(GY)
            movdqa xmm11, xmm0 
            pcmpgtw xmm11, xmm10

            pxor xmm10, xmm11
            psubw xmm10, xmm11

            # abs(GX) + abs(GY)
            paddw xmm9, xmm10



            # if (value > 255) value = 255
            pcmpeqw xmm11, xmm11
            psrlw xmm11, 8

            pminsw xmm9, xmm11


            # result[y * width + x] = (unsigned char)value
            packuswb xmm9, xmm0
            movq qword ptr [r10 + r9], xmm9

            add r9d, 8

        jmp .vector_loop

        .scalar_tail:
            cmp r9d, ebx
            jge .next_row



            # gx = -a + c - 2*d + 2*f - g + i

            # gx = c - a
            movzx eax, byte ptr [rdi + r9 + 1]      # eax = c
            mov dword ptr [rsp + 0], eax

            movzx eax, byte ptr [rdi + r9 - 1]      # eax = a
            sub dword ptr [rsp + 0], eax

            # gx -= 2*d
            movzx eax, byte ptr [rsi + r9 - 1]      # eax = d
            add eax, eax
            sub dword ptr [rsp + 0], eax

            # gx += 2*f
            movzx eax, byte ptr [rsi + r9 + 1]      # eax = f
            add eax, eax
            add dword ptr [rsp + 0], eax 

            # gx -= g
            movzx eax, byte ptr [rcx + r9 - 1]      # eax = g
            sub dword ptr [rsp + 0], eax

            # gx += i
            movzx eax, byte ptr [rcx + r9 + 1]      # eax = i
            add dword ptr [rsp + 0], eax



            # gy = g + 2*h + i - a - 2*b - c

            # gy = g
            movzx eax, byte ptr [rcx + r9 - 1]      # eax = g
            mov dword ptr [rsp + 4], eax

            # gy += 2*h
            movzx eax, byte ptr [rcx + r9]          # eax = h
            add eax, eax
            add dword ptr [rsp + 4], eax   

            # gy += i
            movzx eax, byte ptr [rcx + r9 + 1]      # eax = i
            add dword ptr [rsp + 4], eax

            # gy -= a
            movzx eax, byte ptr [rdi + r9 - 1]      # eax = a
            sub dword ptr [rsp + 4], eax

            # gy -= 2*b
            movzx eax, byte ptr [rdi + r9]          # eax = b
            add eax, eax 
            sub dword ptr [rsp + 4], eax 

            # gy -= c
            movzx eax, byte ptr [rdi + r9 + 1]      # eax = c
            sub dword ptr [rsp + 4], eax



            # value = abs(gx) + abs(gy)
            mov eax, dword ptr [rsp + 0]

            cmp eax, 0
            jge .tail_gx_abs_done
            neg eax

            .tail_gx_abs_done:
            mov dword ptr [rsp + 8], eax

            mov eax, dword ptr [rsp + 4]

            cmp eax, 0
            jge .tail_gy_abs_done
            neg eax

            .tail_gy_abs_done:
            add eax, dword ptr [rsp + 8] 

            cmp eax, 255
            jle .tail_value_ok
            mov eax, 255
            .tail_value_ok:
            # result[y * width + x] = (unsigned char)value
            mov byte ptr [r10 + r9], al

            inc r9d
        jmp .scalar_tail

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
    add rsp, 16

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret

.section .note.GNU-stack,"",@progbits
