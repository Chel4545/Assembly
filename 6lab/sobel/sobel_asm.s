.intel_syntax noprefix

.global sobel_asm
.extern calloc

# передаем:
# rdi = img
# esi = width
# edx = height
#
# возвращаем:
# rax = unsigned char*

sobel_asm:
    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8                 

    mov rbx, rdi   # img
    mov r12d, esi  # width
    mov r13d, edx  # height

    # if (img == NULL) return NULL;
    test rbx, rbx
    jz .return_null

    # if (width <= 0 || height <= 0) return NULL;
    cmp r12d, 0
    jle .return_null

    cmp r13d, 0
    jle .return_null

    # calloc(width * height, sizeof(unsigned char))
    movsxd rax, r12d 
    movsxd rcx, r13d 
    imul rax, rcx 

    mov rdi, rax               
    mov esi, 1

    call calloc

    test rax, rax
    jz .return_null

    mov r14, rax  # r14 result

    # width < 3, height < 3
    cmp r12d, 3
    jl .done

    cmp r13d, 3
    jl .done

    # for (int y = 1; y < height - 1; y++)
    mov r15d, 1                 # y

.outer_loop:
    mov eax, r13d
    dec eax                     # eax = height - 1
    cmp r15d, eax
    jge .done

    # top = img + (y - 1) * width
    # mid = img + y * width
    # bot = img + (y + 1) * width
    # dst = result + y * width

    movsxd rax, r15d 
    dec rax 

    movsxd rdx, r12d  
    imul rax, rdx 

    lea r8, [rbx + rax]         # r8 = top
    mov r9, r8
    add r9, rdx                 # r9 = mid

    mov r10, r9
    add r10, rdx                # r10 = bot

    lea r11, [r14 + rax]
    add r11, rdx                # r11 = dst

    # for (int x = 1; x < width - 1; x++)
    mov ecx, 1                  # x

.inner_loop:
    mov eax, r12d
    dec eax 
    cmp ecx, eax
    jge .next_row


    # eax = c + 2*f + i
    movzx eax, byte ptr [r8 + rcx + 1]      # c
    movzx esi, byte ptr [r9 + rcx + 1]      # f
    lea eax, [eax + esi * 2]                # c + 2*f

    movzx esi, byte ptr [r10 + rcx + 1]     # i
    add eax, esi                            # c + 2*f + i

    # esi = a + 2*d + g
    movzx esi, byte ptr [r8 + rcx - 1]      # a
    movzx edi, byte ptr [r9 + rcx - 1]      # d
    lea esi, [esi + edi * 2]                # a + 2*d

    movzx edi, byte ptr [r10 + rcx - 1]     # g
    add esi, edi                            # a + 2*d + g

    sub eax, esi                            # eax = gx

    # abs(gx)
    test eax, eax
    jge .abs_x_done
    neg eax

    .abs_x_done:

    mov edi, eax                            # edi = abs(gx)


    # edx = g + 2*h + i
    movzx edx, byte ptr [r10 + rcx - 1]     # g
    movzx eax, byte ptr [r10 + rcx]         # h
    lea edx, [edx + eax * 2]                # g + 2*h

    movzx eax, byte ptr [r10 + rcx + 1]     # i
    add edx, eax                            # g + 2*h + i

    # eax = a + 2*b + c
    movzx eax, byte ptr [r8 + rcx - 1]      # a
    movzx esi, byte ptr [r8 + rcx]          # b
    lea eax, [eax + esi * 2]                # a + 2*b

    movzx esi, byte ptr [r8 + rcx + 1]      # c
    add eax, esi                            # a + 2*b + c

    sub edx, eax                            # edx = gy

    # abs(gy)
    mov eax, edx                            # eax = gy
    test eax, eax
    jge .abs_y_done
    neg eax

    .abs_y_done:

    # value = abs(gx) + abs(gy)
    add eax, edi

    # if (value > 255) value = 255;
    cmp eax, 255
    jle .store_pixel

    mov eax, 255

.store_pixel:
    mov byte ptr [r11 + rcx], al            # result[y * width + x] = value

    inc ecx
    jmp .inner_loop

.next_row:
    inc r15d
    jmp .outer_loop

.done:
    mov rax, r14
    jmp .finish

.return_null:
    xor rax, rax

.finish:
    add rsp, 8

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    pop rbp
    ret

.section .note.GNU-stack,"",@progbits