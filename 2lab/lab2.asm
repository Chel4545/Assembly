%ifndef SORT_DIR
%define SORT_DIR 0
%endif

section .data
matrix_rows:
    db 3 ;строки

matrix_col:
    db 3 ;столбцы

matrix:
    dw 1, 2, 3
    dw 4, 5, 6
    dw 7, 8, 9

sort_dir:
    db SORT_DIR ; направление сортировки (0 - возрастание, 1 - убавание)

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

    call fill_tmp_matr
    call fill_main_matr

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
        ; i < n
        cmp r10, rcx
        jae .done

        ; x = sum[i]
        mov r12d, dword [r8 + r10*4]

        ; x_id = ids[i]
        mov r13d, dword [r9 + r10*4]

        ; j = i
        mov r11, r10

        .while_j: ;условия выхода из цикла
            ; j > 0
            test r11, r11
            jz .insert

            ; A[j-1] > x
            mov edx, dword [r8 + r11*4 - 4]
            cmp byte [sort_dir], 0
            je .increase
            jne .decrease

            .decrease:
                cmp edx, r12d
                jge .insert
                jmp .shift

            .increase:
                cmp edx, r12d
                jle .insert
                jmp .shift
            
            .shift:
            ; A[j] = A[j-1]
            mov dword [r8 + r11*4], edx

            ; ids[j] = ids[j-1]
            mov edx, dword [r9 + r11*4 - 4]
            mov dword [r9 + r11*4], edx

            ;j--
            dec r11
            jmp .while_j

    .insert:
    ;A[j] = x
    mov dword [r8 + r11*4], r12d 

    ; ids[j] = x_id
    mov dword [r9 + r11*4], r13d 

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

fill_tmp_matr:
    push rbp
    mov  rbp, rsp

    push r8
    push r9
    push r10
    push r11
    push r13
    push r14
    push r15
    push rax
    push rbx
    push rcx
    push rdx


    movzx r8, byte [matrix_rows] 
    movzx r9, byte [matrix_col]
    lea r10, [matrix]
    lea r11, [tmp]
    lea r13, [ids]

    xor r14b, r14b

    .for_col:
        cmp r14b, r9b
        jge .cal_end

        mov eax, dword [r13 + r14*4] ; id
        mov ebx, eax                 ; id

        xor r15b, r15b
        .for_row:
            cmp r15b, r8b
            jge .row_end


            mov rax, r15 ; смещение для matr
            imul rax, r9 ; j*offcet + it
            add rax, rbx

            mov cx, word [r10 + rax*2] ; база + 2(размер элементов) * смещение

            mov rdx, r15 ; аналогично с первым но для tmp
            imul rdx, r9
            add rdx, r14

            mov word [r11 + rdx*2], cx

            inc r15b
            jmp .for_row

        .row_end:
 
        inc r14b
        jmp .for_col

    .cal_end:

    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop r15
    pop r14
    pop r13
    pop r11
    pop r10
    pop r9
    pop r8

    mov rsp, rbp
    pop rbp
    ret 

fill_main_matr:
    push rbp
    mov  rbp, rsp

    push r8
    push r9
    push r10
    push r11
    push r12
    push rax

    movzx r8,  byte [matrix_rows] 
    movzx r9,  byte [matrix_col] 
    lea   r10,      [matrix] 
    lea   r11,      [tmp]

    xor r12, r12
    imul r8, r9

    .loop_fill:
        cmp r12b, r8b
        jge .loop_end

        mov ax, word [r11 + r12*2]
        mov word [r10 + r12*2], ax 

        inc r12b
        jmp .loop_fill
    .loop_end:

    pop rax
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8

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

        movzx rcx, r9b
        call col_sum 
        mov dword [sum + r9*4], eax

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

        mov byte [ids + r9*4], r9b

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
    push r15

    movzx r8,  byte [matrix_rows]   ;строки
    movzx r9,  byte [matrix_col] ;колонки
    lea   r10,      [matrix] ;база
    mov   r11, r9            ;офсет
    shl   r11, 1             ;офсет

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

    pop r15
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