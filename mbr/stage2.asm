section header vstart=0
    program_length dd program_end
    code_entry dw start
               dd section.code1.start

    realloc_tabl_length dw (header_end - code1_seg_addr) / 4

    code1_seg_addr dd section.code1.start
    code2_seg_addr dd section.code2.start
    data1_seg_addr dd section.data1.start
    data2_seg_addr dd section.data2.start
    stack_seg_addr dd section.stack.start
header_end:

section code1 align=16 vstart=0
print_string:
    mov cl, [bx]
    or cl, cl
    jz .exit
    call print_char
    inc bx
    jmp print_string
.exit:
    ret

print_char:
    push ax
    push bx
    push cx
    push dx
    push ds
    push es

    ; 获取光标当前的位置
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    in al, dx
    mov ah, al

    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx
    ; AX中存储了光标16位位置
    mov bx, ax

    ; 判断字符是不是回车
    cmp cl, 0x0d
    ; 不是回车，看看是不是换行
    jnz .print_next_line
    mov bl, 80
    ; 除以80，得到行号
    div bl
    ; 乘以80，得到新的光标位置
    mul bl
    mov bx, ax
    jmp .set_cursor

.print_next_line:
    ; 换行
    cmp cl, 0x0a
    jnz .print_normal_char
    add bx, 80
    jmp .roll_screen

.print_normal_char:
    mov ax, 0xb800
    mov es, ax
    shl bx, 1
    mov [es:bx], cl

    shr bx, 1
    add bx, 1

.roll_screen:
    ; 判断光标是否超出屏幕
    cmp bx, 2000
    ; 小于2000，说明没有超出屏幕
    jl .set_cursor

    push bx

    mov ax, 0xb800
    mov ds, ax
    mov es, ax
    cld
    mov si, 0xa0
    mov di, 0x00
    mov cx, 1920
    rep movsw
    mov bx, 3840
    mov cx, 80

.cls:
    mov word[es:bx], 0x0720
    add bx, 2
    loop .cls

    pop bx
    ; 光标换行前的原始行位置
    sub bx, 80

.set_cursor:
    ; 设置光标位置
    mov dx,0x3d4
    mov al,0x0e
    out dx,al
    mov dx,0x3d5
    mov al,bh
    out dx,al
    mov dx,0x3d4
    mov al,0x0f
    out dx,al
    mov dx,0x3d5
    mov al,bl
    out dx,al

    pop es
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax

    ret


start:
    mov ax, [stack_seg_addr]
    mov ss, ax
    mov sp, stack_end

    mov ax, [data1_seg_addr]
    mov ds, ax

    mov bx, message1
    call print_string

    push word [es:code2_seg_addr]
    mov ax, begin
    push ax

    retf

countinue_here:
    mov ax, [es:data2_seg_addr]
    mov ds, ax

    mov bx, message2
    call print_string

    jmp $


section code2 align=16 vstart=0
begin:
    push word [es:code1_seg_addr]
    mov ax, countinue_here
    push ax

    retf


section data1 align=16 vstart=0
message1 db '  This is NASM - the famous Netwide Assembler. ',0x0d,0x0a
        db 'Back at SourceForge and in intensive development! ',0x0d,0x0a
        db 'Get the current versions from http://www.nasm.us/.',0x0d,0x0a
        db 0x0d,0x0a,0x0d,0x0a
        db 0
section data2 align=16 vstart=0
message2 db '  The above contents is written by LeeChung. '
        db '2011-05-06'
        db 0
section stack align=16 vstart=0
    resb 256
stack_end:

section trail align=16
program_end: