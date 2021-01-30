[bits 32]


%macro absd 1 
    mov     eax,    %1
    shr     eax,    31
    xor     %1,     eax 
    sub     %1,     eax 
%endmacro


    global flipdiagbmp24
flipdiagbmp24:
    push    ebp
    mov     ebp, esp 
    sub     esp, 12
    push    ebx 
    push    esi 
    push    edi 

    mov     edi,    [ebp + 8]   ; pointer to the buffer
    mov     esi,    [ebp + 12]  ; buffer size

    ; check bmp header
    cmp word [edi], "BM"
    mov     eax,    -1  
    jne     .return

    ; check if bits per pixel == 24
    mov     ebx,    [edi + 28]
    cmp     ebx,    24           
    mov     eax,    -2   
    jne     .return

    ; check if width == height
    mov     ebx,    [edi + 18]
    mov     ecx,    [edi + 22] 
    absd    ecx     
    cmp     ebx,    ecx 
    mov     eax,    -3
    jne     .return

    ; calc padding
    lea     edx,    [2 * ebx + ebx]
    and     edx,    3
    sub     edx,    4
    neg     edx 
    and     edx,    3

    ; check if bitmap isn't too big 
    lea     eax,    [2 * ebx + ebx]
    add     eax,    edx 
    mov     ecx,    edx
    mul     ebx
    mov     edx,    ecx
    mov     ecx,    eax
    add     ecx,    [edi + 10] ; add offset 
    cmp     ecx,    esi
    mov     eax,    -4   
    jg      .return

    ; [edi + 18] - picture size 
    ; [ebp - 4]  - beginning of pixel data 
    ; [ebp - 8]  - end of pixel data
    ; [ebp - 12] - row length
    ; ebx - i
    ; ecx - j
    ; edx - p
    ; esi - r
    mov     eax,    edi 
    add     eax,    [edi + 10]
    mov     [ebp - 4], eax
    lea     eax,    [edi + ecx - 3] 
    sub     eax,    edx 
    mov     [ebp - 8], eax 
    lea     eax,    [2 * ebx + ebx]
    add     eax,    edx 
    mov     [ebp - 12], eax 
    xor     ebx,    ebx 
.loop_0:
    mov     edx,    [ebp - 4]
    mov     esi,    [ebp - 8]
    mov     ecx,    [edi + 18]
    sub     ecx,    ebx
.loop_1:
%assign i 0
%rep 3
    mov     al,     [edx + i]
    xchg    al,     [esi + i]
    mov     [edx + i], al
%assign i i+1
%endrep 

    add     edx,    3
    sub     esi,    [ebp - 12]
    dec     ecx 
    jnz     .loop_1

    mov     eax,    [ebp - 12]
    add     [ebp - 4], eax 
    sub dword [ebp - 8], 3
    inc     ebx 
    cmp     ebx,    [edi + 18]
    jne     .loop_0

    xor     eax,    eax
.return:
    pop     edi 
    pop     esi 
    pop     ebx
    mov     esp, ebp 
    pop     ebp
    ret
