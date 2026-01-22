[BITS 16]
[ORG 0x7C00]
start:
    mov ax, 0xb800
    mov es, ax

    mov si, message_start
    mov di, 0
    mov cx, message_end - message_start
show_message:
    mov al, [si]
    mov [es:di], al
    inc di
    mov byte [es:di], 0x37
    inc di
    inc si
    loop show_message

    xor ax,ax
    mov cx,1
num_sum:
    add ax, cx
    inc cx
    cmp cx, 100
    jle num_sum

    xor cx, cx
    mov ss, cx
    mov sp, cx

    mov bx, 10
get_digit:
    inc cx
    xor dx, dx
    div bx
    or dl, '0'
    push dx
    cmp ax, 0
    jne get_digit
show_digit:
    pop dx
    mov [es:di],dl
    inc di
    mov byte [es:di], 0x37
    inc di
    loop show_digit

hang:
    jmp near hang
message_start db "1+2+3+...+100="
message_end db 0
times 510-($-$$) db 0
dw 0xAA55


