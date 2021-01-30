[bits 64]


%macro absd 1 
    mov     eax,    %1
    shr     eax,    31
    xor     %1,     eax 
    sub     %1,     eax 
%endmacro


    global flipdiagbmp24
flipdiagbmp24:
    push    r12 
    push    r13
    push    r14
    push    r15

    ; check bmp header
    cmp word [rdi], "BM"
    mov     rax,    -1  
    jne     .return

    mov     r8d,    [rdi + 10]  ; offset
    mov     r9d,    [rdi + 18]  ; picture width 
    mov     r10d,   [rdi + 22]  ; picture height
    absd    r10d
    mov     r11w,   [rdi + 28]  ; bits per pixel

    ; check if bits per pixel == 24
    cmp     r11w,   24           
    mov     rax,    -2   
    jne     .return

    ; check if width == height
    cmp     r9d,    r10d 
    mov     rax,    -3
    jne     .return

    ; calc padding
    lea     r12d,   [2 * r9d + r9d]
    and     r12d,   3
    sub     r12d,   4
    neg     r12d 
    and     r12d,   3

    ; check if bitmap isn't too big 
    xor     rax,    rax
    lea     eax,    [2 * r9d + r9d]
    add     eax,    r12d 
    mul     r9d
    mov     r10d,   eax
    add     r10d,   r8d 
    cmp     r10,    rsi
    mov     rax,    -4   
    jg      .return

    ; r9d - picture size 
    ; r11 - beginning of pixel data 
    ; r10 - end of pixel data
    ; r8d - row length
    ; r12d - i
    ; r13d - j
    ; r14 - p
    ; r15 - r
    lea     r11,    [rdi + r8] 
    add     r10,    rdi         
    sub     r10,    r12        
    sub     r10,    3           
    lea     r8d,    [2 * r9d + r9d]
    add     r8d,    r12d        
    xor     r12d,   r12d 
.loop_0:
    mov     r14,    r11 
    mov     r15,    r10 
    mov     r13d,   r9d 
    sub     r13d,   r12d
.loop_1:
%assign i 0
%rep 3
    mov     al,     [r14 + i]
    xchg    al,     [r15 + i]
    mov     [r14 + i], al
%assign i i+1
%endrep 

    add     r14,    3 
    sub     r15,    r8
    dec     r13d 
    jnz     .loop_1

    add     r11,    r8 
    sub     r10,    3
    inc     r12d 
    cmp     r12d,   r9d 
    jne     .loop_0

    xor     rax,    rax
.return:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

