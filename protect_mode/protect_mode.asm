; 设置栈帧
mov ax, cs
mov ss, ax
mov sp, 0x7c00

mov ax, [cs:gdt_base+ 0x7c00]
mov dx, [cs:gdt_base+ 0x7c02]
mov bx, 16
div bx

mov ds, ax
mov bx, dx


; GDT第0项是NULL描述符
mov dword [bx+0x00], 0x00
mov dword [bx+0x04], 0x00

; GDT第1项是数据段描述符
; 基址0x000b8000，界限0x0FFFF
mov dword [bx+0x08], 0x8000ffff
mov dword [bx+0x0c], 0x0040920b

; GDT大小为字节数-1, 15
mov word [cs:gdt_size+0x7c00], 15

lgdt [cs:gdt_size+0x7c00]


; 启用A20
in al, 0x92
or al, 0000_0010B
out 0x92, al

; BIOS是16位的，会自动打开中断，32位不能运行，这里关掉
cli

mov eax,cr0
or eax,1
; 设置PE位
mov cr0,eax

; 向ds中写入段选择子
mov cx, 0x08
mov ds, cx

;以下在屏幕上显示"Protect mode OK."
mov byte [0x00],'P'
mov byte [0x02],'r'
mov byte [0x04],'o'
mov byte [0x06],'t'
mov byte [0x08],'e'
mov byte [0x0a],'c'
mov byte [0x0c],'t'
mov byte [0x0e],' '
mov byte [0x10],'m'
mov byte [0x12],'o'
mov byte [0x14],'d'
mov byte [0x16],'e'
mov byte [0x18],' '
mov byte [0x1a],'O'
mov byte [0x1c],'K'
mov byte [0x1e],'.'

; 已经禁止中断，将不会被唤醒
hlt


gdt_size dw 0
gdt_base dd 0x00007e00               ;GDT的物理地址
times 510-($-$$) db 0
dw 0xAA55                           ;引导扇区标志