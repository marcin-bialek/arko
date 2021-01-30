    section .text
    global swapln
swapln:
    push    ebp
    mov     ebp, esp 
    push    ebx 
    push    edi 

    mov     eax, [ebp + 8]  ; wskażnik na string 
    mov     ecx, [ebp + 12] ; n 
    dec     ecx 
    mov     bl, [eax]
    test    bl, bl 
    jz      .return 
.loop_0:
    cmp     bl, '0'
    jb      .next_0
    cmp     bl, '9'
    ja      .next_0

    lea     edi, [eax + 1] 
    mov     bh, [edi]
    test    bh, bh 
    jz      .return 
.loop_1:
    cmp     bh, '0'
    jb      .next_1
    cmp     bh, '9'
    ja      .next_1
    dec     ecx 
    jnz     .next_1
    ; Zamiana liter
    mov     [eax], bh
    mov     [edi], bl
    mov     eax, edi
    mov     ecx, [ebp + 12] ; n   
    dec     ecx
    jmp     .next_0
.next_1:
    inc     edi 
    mov     bh, [edi]
    test    bh, bh 
    jnz      .loop_1
    jmp     .return   
.next_0:
    inc     eax 
    mov     bl, [eax]
    test    bl, bl 
    jnz      .loop_0 
.return:
    mov     eax, [ebp + 8]
    pop     edi 
    pop     ebx 
    mov     esp, ebp 
    pop     ebp 
    ret 