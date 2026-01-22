; ============================================================================
; 内核加载的起始内存地址
core_base_addr equ 0x00040000
; 内核在磁盘上的起始扇区号
core_lba_start equ 1

; ============================================================================
; 代码开始
    mov ax, cs
    mov ss, ax
    mov sp, 0x7c00

    mov eax, [cs:pgdt + 0x7c02]
    xor edx, edx
    mov ebx, 16
    div ebx

    mov ds, eax
    mov ebx, edx


    ; 跳过gdt 0号位置
    ; 创建1号描述符
    mov dword [ebx+0x08],0x0000ffff    ;基地址为0，段界限为0xFFFFF
    mov dword [ebx+0x0c],0x00cf9200    ;粒度为4KB，存储器段描述符

    ; 创建保护模式下初始代码段描述符
    mov dword [ebx+0x10], 0x7c0001ff    ;基地址为0x00007c00，界限0x1FF
    mov dword [ebx+0x14], 0x00409800    ;粒度为1个字节，代码段描述符

    ;建立保护模式下的堆栈段描述符      ;基地址为0x00007C00，界限0xFFFFE
    mov dword [ebx+0x18],0x7c00fffe    ;粒度为4KB
    mov dword [ebx+0x1c],0x00cf9600

    ;建立保护模式下的显示缓冲区描述符
    mov dword [ebx+0x20],0x80007fff    ;基地址为0x000B8000，界限0x07FFF
    mov dword [ebx+0x24],0x0040920b    ;粒度为字节

    ; 加载GDT到GDTR寄存器
    mov word [cs:pgdt + 0x7c00], 39
    lgdt  [cs:pgdt + 0x7c00]


    ; A20线打开
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 关闭16位下的BIOS中断
    cli

    ; 开启保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到保护模式下的代码段
    jmp 0x0010:flush

[bits 32]
flush:
    ; 加载1号描述符段选择子
    mov ax, 0x0008
    mov ds, ax

    ; 加载堆栈段选择子
    mov eax, 0x0018
    mov ss, eax
    xor esp, esp

    ; 加载内核程序
    mov edi, core_base_addr
    mov eax, core_lba_start
    mov ebx, edi
    call read_hdd32

    ; 判断程序大小
    mov eax, [edi]
    xor edx, edx
    mov ecx, 512
    div ecx

    ; 余数不为0，说明有长度小于512字节的部分
    or edx, edx
    jnz .less_sector_size

    ; 整除的情况
    ; 已经读过一个扇区，减去1
    dec eax


.less_sector_size:
    ; 判断是否还有剩余扇区需要读取
    ; 第一个扇区已经读过，小于512字节其实已经被包含
    ; 此时商如果是0，则跳转到setup，不是0则继续读取剩余扇区
    or eax, eax
    jz setup

    ; 读取剩余的扇区
    mov ecx, eax
    mov eax, core_lba_start
    inc eax
.read_left_sector:
    call read_hdd32
    inc eax
    loop .read_left_sector


setup:
    ; 我们不能直接使用CS:,但可以使用4GB段开始访问
    mov esi, [0x7c00 + pgdt + 0x02]

    ; 建立公共例程段描述符
    mov eax, [edi+0x04]
    mov ebx, [edi+0x08]
    sub ebx, eax
    ; 注意减1是段界限是最大允许访问的偏移，不是长度
    dec ebx
    add eax, edi
    mov ecx, 0x00409800
    call make_segment_descriptor
    mov [esi+0x28], eax
    mov [esi+0x2c], edx

    ;建立核心数据段描述符
    mov eax, [edi+0x08]
    mov ebx, [edi+0x0c]
    sub ebx, eax
    dec ebx
    add eax, edi
    mov ecx, 0x00409200
    call make_segment_descriptor
    mov [esi+0x30], eax
    mov [esi+0x34], edx

    ;建立核心代码段描述符
    mov eax, [edi+0x0c]
    mov ebx, [edi+0x00]
    sub ebx, eax
    dec ebx
    add eax, edi
    mov ecx, 0x00409800
    call make_segment_descriptor
    mov [esi+0x38], eax
    mov [esi+0x3c], edx

    ; 重载GDTR
    mov word [0x7c00+pgdt], 63
    lgdt [0x7c00+pgdt]

    ; 跳转到内核代码段
    jmp far [edi+0x10]


; ==============================================================================
; EAX 为读取的扇区数
; DS:EBX 为读取到内存的地址
read_hdd32:
    %include "read_hdd32.inc"
    ret

; ==============================================================================
; 输入：
; EAX 线性基地址
; EBX 段界限
; ECX 属性
; 输出：EDX:EAX 完整的描述符
make_segment_descriptor:
    %include "make_seg_descriptor.inc"
    ret

    pgdt    dw  0
            dd  0x00007e00

    times   510-($-$$)  db  0
    dw  0xaa55