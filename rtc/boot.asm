; 用户代码所在的磁盘逻辑扇区位置
app_lba_start equ 100

; 引导扇区
section mbr align=16 vstart=0x7c00
    mov ax, 0
    mov ss, ax
    mov sp, ax

    ; 将es和ds的段地址设为0x1000（注意真实地址需要/16）
    mov ax, [cs:mem_phy_addr]
    mov dx, [cs:mem_phy_addr + 0x02]
    mov bx, 16
    div bx
    mov ds, ax
    mov es, ax

    ; 加载用户代码
    xor di, di
    mov si, app_lba_start
    xor bx, bx
    call read_hdd

    ; 开始地址重定向工作

    ; 计算用户代码的代码大小
    mov ax, [0x00]
    mov dx, [0x02]
    mov bx, 512
    div bx
    ; 余数为0，为整除
    cmp dx, 0
    ; 未除尽，说明有剩余，需要进行额外处理
    jnz .extra_code_load
    dec ax
.extra_code_load:
    cmp ax, 0
    jz .load_done

    ; 继续加载剩余的用户代码
    push ds

    mov cx, ax

.loop_load:
    ; 得到下一个512字节的内存数据区
    mov ax, ds
    ; 左移4位后就是512
    add ax, 0x20
    mov ds, ax

    xor bx, bx
    ; 下一个逻辑扇区
    inc si
    call read_hdd
    loop .loop_load

    pop ds

.load_done:
    ; 计算入口点代码段地址
    mov ax, [0x06]
    mov dx, [0x08]
    call calc_seg_addr
    mov [0x06], ax

    ; 处理段重定位表
    mov cx, [0x0a]
    mov bx, 0x0c
realloc:
    mov ax, [bx]
    mov dx, [bx+0x02]
    call calc_seg_addr
    mov [bx], ax
    add bx, 4
    loop realloc

    ; 跳转到用户程序
    jmp far [0x04]


; 读取磁盘扇区的数据到内存中
; 参数：
;   DI:SI : 逻辑扇区地址
;   DS:BX : 内存中的地址
read_hdd:
    push ax
    push bx
    push cx
    push dx

    ; 指定扇区个数为1
    mov dx, 0x1f2
    mov al, 1
    out dx, al

    inc dx
    mov ax, si
    out dx, al

    inc dx
    mov al, ah
    out dx, al

    inc dx
    mov ax, di
    out dx, al

    inc dx
    mov al, 0xe0
    ; 这一步的地址得保证di的高位也写入
    or al, ah
    out dx, al

    ; 读命令
    inc dx
    mov al, 0x20
    out dx, al

.wait_status:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .wait_status

    mov cx, 256
    mov dx, 0x1f0
.read_data:
    in ax, dx
    mov [bx], ax
    add bx, 2
    loop .read_data

    pop dx
    pop cx
    pop bx
    pop ax

    ret

; 计算段地址
; 参数：
;    DX:AX : 用户逻辑段地址
; 返回：
;    AX : 段地址
calc_seg_addr:
    push dx

    add ax, [cs:mem_phy_addr]
    adc dx, [cs:mem_phy_addr + 0x02]
    ; 段地址在DX:AX中, 右移4位的20位为真实结果
    shr ax, 4
    ror dx,4
    and dx,0xf000
    or ax,dx

    pop dx
    ret


; 用户代码被加载在内存中的位置
mem_phy_addr dd 0x10000
times 510-($-$$) db 0
dw 0xaa55


