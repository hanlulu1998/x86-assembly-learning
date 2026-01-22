    push eax
    push ecx
    push edx

    push eax
    mov dx, 0x1f2

    ; 读取一个扇区
    mov al, 1
    out dx, al

    ; 0x1f3
    inc dx
    ; LBA 7~0
    pop eax
    out dx,al

    ; 0x1f4
    inc dx
    ; LBA 15~8
    mov cl, 8
    shr eax, cl
    out dx, al

    ; 0x1f5
    inc dx
    shr eax, cl
    ; LBA 23~16
    out dx,al

    ; 0x1f6
    inc dx
    ; LBA 27~24
    shr eax, cl
    or al, 0xe0
    out dx,al

    ; 0x1f7
    inc dx
    ; 读数据
    mov al, 0x20
    out dx,al

    ; 等待硬盘就绪
.wait_status:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .wait_status

    ; 读数据到内存
    mov ecx, 256
    mov dx, 0x1f0
.read_loop:
    in ax, dx
    mov [ebx], ax
    add ebx, 2
    loop .read_loop

    pop edx
    pop ecx
    pop eax