section .data
matrix_rows:
    db 3 ;строки
matrix_col:
    db 3 ;столбцы

matrix:
    dw 3, 2, 1
    dw 6, 5, 4
    dw 9, 8, 7


section .bss
    tmp: resw 255*255
    sum: resd 255
    ids: resd 255


section .text
    global _start

_start:
    call fill_sum
    call fill_ids

    call sort_sum



    jmp ok

sort_sum:
    push rbp
    mov  rbp, rsp

    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push rcx
    push rdx 

    lea   r8, [sum]
    lea   r9, [ids]
    movzx rcx, byte [matrix_col]

    cmp rcx, 1
    jbe .done

    mov r10, 1

    .for_i:

        cmp r10, rcx
        jae .done

        ; x = sum[i]
        mov r12d, [r8 + r10*4]

        ; x_id = ids[i]
        mov r13d, [r9 + r10*4]

        ; j = i
        mov r11, r10

        .while_j:

            test r11, r11
            jz .insert

            ; A[j-1]
            mov edx, [r8 + r11*4 - 4]    
            cmp edx, r12d
            jle .insert

            ; A[j] = A[j-1]
            mov [r8 + r11*4], edx

            ; ids[j] = ids[j-1]
            mov edx, [r9 + r11*4 - 4]
            mov [r9 + r11*4], edx

            ;j--
            dec r11
            jmp .while_j

    .insert:
    ;A[j] = x
    mov [r8 + r11*4], r12d 

    ; ids[j] = x_id
    mov [r9 + r11*4], r13d 

    inc r10
    jmp .for_i

    .done:
    pop rdx
    pop rcx
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8

    mov rsp, rbp
    pop rbp
    ret

fill_matr:
    push rbp
    mov  rbp, rsp

    movzx r8,  byte [matrix_rows] 
    movzx r9,  byte [matrix_col] 
    lea   r10,      [matrix] 
    lea   r11,      [r9*2]

    xor r12d, r12d

    .loop_fill:
        cmp r12b, r9b
        jge .loop_end

        mov r12, [ids + r12b*2]
        mov ax, word [matrix + r12b*2]
        mov word []


        inc r12b
        jmp .loop_fill

    .loop_end:

    mov rsp, rbp
    pop rbp
    ret   

; cl=A, dl=B
swap_blocks:
    push rbp
    mov  rbp, rsp

    push rbx
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12

    movzx r8,  byte [matrix_rows]   ;строки(movzx для инициализации верхних битов 0)
    movzx r9,  byte [matrix_col] ;колонки
    lea   r10,      [matrix] ;база
    lea   r11,      [r9*2]     ;офсет

    lea rbx, [r10 + rcx*2] ;1 столбец
    lea rdi, [r10 + rdx*2] ;2 столбец

    xor r12d, r12d

    .loop_start_A_to_TMP:
        cmp r12b, r8b ;условие
        jge .loop_end_A_to_TMP

        mov  rax, r12
        imul rax, r11             ; rax = r12*r11
        mov  ax,  word [rbx + rax]
        mov  word [tmp + r12*2], ax

        inc r12b
        jmp .loop_start_A_to_TMP

    .loop_end_A_to_TMP:

    xor r12d, r12d

    .loop_start_B_to_A:
        cmp r12b, r8b 
        jge .loop_end_B_to_A

        mov  rax, r12
        imul rax, r11
        mov  ax,  word [rdi + rax]
        mov  word [rbx + rax], ax

        inc r12b
        jmp .loop_start_B_to_A

    .loop_end_B_to_A:

    xor r12d, r12d

    .loop_start_TMP_to_B:
        cmp r12b, r8b 
        jge .loop_end_TMP_to_B

        mov  ax,  word [tmp + r12*2]
        mov  rax, r12
        imul rax, r11
        mov  word [rdi + rax], ax

        inc r12b
        jmp .loop_start_TMP_to_B

    .loop_end_TMP_to_B:

    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rbx

    mov rsp, rbp
    pop rbp
    ret

fill_sum:
    push rbp
    mov  rbp, rsp

    push r8
    push r9

    movzx r8, byte [matrix_col]
    xor   r9, r9

    .loop_start:
        cmp r9b, r8b ;условие
        jge .loop_end

        mov cl, r9b
        call col_sum 
        mov [sum + r9*4], eax

        inc r9b
        jmp .loop_start

    .loop_end: 

    pop r9
    pop r8

    mov rsp, rbp
    pop rbp
    ret

fill_ids:
    push rbp
    mov  rbp, rsp

    push r8
    push r9

    movzx r8, byte [matrix_col]
    xor   r9, r9

    .loop_start:
        cmp r9b, r8b ;условие
        jge .loop_end

        mov [ids + r9*4], r9

        inc r9b
        jmp .loop_start

    .loop_end: 

    pop r9
    pop r8

    mov rsp, rbp
    pop rbp
    ret


col_sum: ;cl - id столбец
    push rbp
    mov  rbp, rsp

    push rbx
    push r8
    push r9
    push r10
    push r11
    push r12

    movzx r8,  byte [matrix_rows]   ;строки
    movzx r9,  byte [matrix_col] ;колонки
    lea   r10,      [matrix] ;база
    lea   r11,      [r9*2] ;офсет

    lea rbx, [r10 + rcx*2] ;начало

    xor eax, eax
    xor r12, r12

    .loop_start:
        cmp r12, r8 ;условие
        jge .loop_end

        mov rdx, r12
        imul rdx, r11
        movsx r15d, word [rbx + rdx]
        add eax, r15d

        inc r12
        jmp .loop_start

    .loop_end:

    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbx

    mov rsp, rbp
    pop rbp
    ret

ok:
    mov rax, 60
    xor rdi, rdi
    syscall