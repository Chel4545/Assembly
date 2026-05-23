.intel_syntax noprefix

.global sobel_asm_vector
.extern calloc

# передаем:
# rdi = img
# esi = width
# edx = height
#
# возвращаем:
# rax = unsigned char*

sobel_asm_vector:
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

    pxor xmm15, xmm15

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
    sub eax, 17 
    cmp ecx, eax
    jg .next_row


    movdqu xmm8,  xmmword ptr [r8  + rcx - 1]   # a: top[x-1 .. x+14]
    movdqu xmm9,  xmmword ptr [r8  + rcx]       # b: top[x   .. x+15]
    movdqu xmm10, xmmword ptr [r8  + rcx + 1]   # c: top[x+1 .. x+16]

    movdqu xmm11, xmmword ptr [r9  + rcx - 1]   # d: mid[x-1 .. x+14]
    movdqu xmm12, xmmword ptr [r9  + rcx + 1]   # f: mid[x+1 .. x+16]

    movdqu xmm13, xmmword ptr [r10 + rcx - 1]   # g: bot[x-1 .. x+14]
    movdqu xmm14, xmmword ptr [r10 + rcx]       # h: bot[x   .. x+15]
    movdqu xmm7,  xmmword ptr [r10 + rcx + 1]   # i: bot[x+1 .. x+16]

    # gx
    # xmm0 = c
    movdqa xmm0, xmm10
    punpcklbw xmm0, xmm15

    # xmm1 = 2*f
    movdqa xmm1, xmm12
    punpcklbw xmm1, xmm15
    paddw xmm1, xmm1

    # xmm0 = c + 2*f
    paddw xmm0, xmm1

    # xmm1 = i
    movdqa xmm1, xmm7
    punpcklbw xmm1, xmm15

    # xmm0 = c + 2*f + i
    paddw xmm0, xmm1

    # xmm2 = a
    movdqa xmm2, xmm8
    punpcklbw xmm2, xmm15

    # xmm3 = 2*d
    movdqa xmm3, xmm11
    punpcklbw xmm3, xmm15
    paddw xmm3, xmm3

    # xmm2 = a + 2*d
    paddw xmm2, xmm3

    # xmm3 = g
    movdqa xmm3, xmm13
    punpcklbw xmm3, xmm15

    # xmm2 = a + 2*d + g
    paddw xmm2, xmm3

    # xmm0 = gx
    psubw xmm0, xmm2

    # xmm0 = abs(gx)
    movdqa xmm4, xmm0
    psraw xmm4, 15
    pxor xmm0, xmm4
    psubw xmm0, xmm4

    # gy
    # xmm5 = g
    movdqa xmm5, xmm13
    punpckhbw xmm5, xmm15

    # xmm6 = 2*h
    movdqa xmm6, xmm14
    punpckhbw xmm6, xmm15
    paddw xmm6, xmm6

    # xmm5 = g + 2*h
    paddw xmm5, xmm6

    # xmm6 = i
    movdqa xmm6, xmm7
    punpckhbw xmm6, xmm15

    # xmm5 = g + 2*h + i
    paddw xmm5, xmm6

    # xmm2 = a
    movdqa xmm2, xmm8
    punpckhbw xmm2, xmm15

    # xmm3 = 2*b
    movdqa xmm3, xmm9
    punpckhbw xmm3, xmm15
    paddw xmm3, xmm3

    # xmm2 = a + 2*b
    paddw xmm2, xmm3

    # xmm3 = c
    movdqa xmm3, xmm10
    punpckhbw xmm3, xmm15

    # xmm2 = a + 2*b + c
    paddw xmm2, xmm3

    # xmm5 = gy
    psubw xmm5, xmm2

    # xmm5 = abs(gy)
    movdqa xmm4, xmm5
    psraw xmm4, 15
    pxor xmm5, xmm4
    psubw xmm5, xmm4

    paddw xmm1, xmm5


.store_pixel:
    packuswb xmm0, xmm1

    movdqu xmmword ptr [r11 + rcx], xmm0

    add ecx, 16

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