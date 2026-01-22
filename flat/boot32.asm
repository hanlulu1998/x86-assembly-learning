; ============================================================================
; 内核加载的起始内存地址
core_base_addr equ 0x00040000
; 内核在磁盘上的起始扇区号
core_lba_start equ 1

section mbr vstart=0x00007c00
; ============================================================================
; 代码开始
    xor ax, ax                         ;ax <- 0
    mov ds, ax
    mov ss, ax
    mov sp, 0x7c00

    ;计算GDT所在的逻辑段地址
    mov eax, [pgdt + 0x02]             ;GDT的32位物理地址
    xor edx, edx
    mov ebx, 16
    div ebx                            ;分解成16位逻辑地址

    mov ds,eax                         ;令DS指向该段以进行操作
    mov ebx,edx                        ;段内起始偏移地址



    ;跳过0#号描述符的槽位
    ;创建1#描述符，保护模式下的代码段描述符，特权级为0
    mov dword [ebx+0x08], 0x0000ffff   ;基地址为0，界限0xFFFFF，DPL=00
    mov dword [ebx+0x0c], 0x00cf9800   ;4KB粒度，代码段描述符，向上扩展

    ;创建2#描述符，保护模式下的数据段和堆栈段描述符，特权级为0
    mov dword [ebx+0x10], 0x0000ffff   ;基地址为0，界限0xFFFFF，DPL=00
    mov dword [ebx+0x14], 0x00cf9200   ;4KB粒度，数据段描述符，向上扩展

    ;创建3#描述符，保护模式下的代码段描述符，特权级为3
    mov dword [ebx+0x18], 0x0000ffff   ;基地址为0，界限0xFFFFF，DPL=11
    mov dword [ebx+0x1c], 0x00cff800   ;4KB粒度，代码段描述符，向上扩展

    ;创建4#描述符，保护模式下的数据段和堆栈段描述符，特权级为3
    mov dword [ebx+0x20], 0x0000ffff   ;基地址为0，界限0xFFFFF，DPL=11
    mov dword [ebx+0x24], 0x00cff200   ;4KB粒度，代码段描述符，向上扩展


    ;初始化描述符表寄存器GDTR
    mov word [cs: pgdt],39             ;描述符表的界限

    ;初始化描述符表寄存器GDTR
    mov word [cs: pgdt],39             ;描述符表的界限
    lgdt [cs: pgdt]


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

    ;以下进入保护模式... ...
    jmp dword 0x0008:flush             ;16位的描述符选择子：32位偏移
                                        ;清流水线并串行化处理器

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
    jz setup_page

    ; 读取剩余的扇区
    mov ecx, eax
    mov eax, core_lba_start
    inc eax
.read_left_sector:
    call read_hdd32
    inc eax
    loop .read_left_sector

; ------------------------------------------------------------------------------
; 设置分页并跳转
setup_page:
    ;创建系统内核的页目录表PDT
    mov ebx,0x00020000                 ;页目录表PDT的物理地址

    ;在页目录内创建指向页目录表自己的目录项
    mov dword [ebx+4092],0x00020003

    mov edx,0x00021003                 ;MBR空间有限，后面尽量不使用立即数
    ;在页目录内创建与线性地址0x00000000对应的目录项
    mov [ebx+0x000],edx                ;写入目录项（页表的物理地址和属性）
                                    ;此目录项仅用于过渡。
    ;在页目录内创建与线性地址0x80000000对应的目录项
    mov [ebx+0x800],edx                ;写入目录项（页表的物理地址和属性）

    ;创建与上面那个目录项相对应的页表，初始化页表项
    mov ebx,0x00021000                 ;页表的物理地址
    xor eax,eax                        ;起始页的物理地址
    xor esi,esi
.b1:
    mov edx,eax
    or edx,0x00000003
    mov [ebx+esi*4],edx                ;登记页的物理地址
    add eax,0x1000                     ;下一个相邻页的物理地址
    inc esi
    cmp esi,256                        ;仅低端1MB内存对应的页才是有效的
    jl .b1

    ;令CR3寄存器指向页目录，并正式开启页功能
    mov eax,0x00020000                 ;PCD=PWT=0
    mov cr3,eax

    ;将GDT的线性地址映射到从0x80000000开始的相同位置
    sgdt [pgdt]
    ;mov ebx,[pgdt+2]
    add dword [pgdt+2],0x80000000      ;GDTR也用的是线性地址
    lgdt [pgdt]

    mov eax,cr0
    or eax,0x80000000
    mov cr0,eax                        ;开启分页机制

    ;将堆栈映射到高端，这是非常容易被忽略的一件事。应当把内核的所有东西
    ;都移到高端，否则，一定会和正在加载的用户任务局部空间里的内容冲突，
    ;而且很难想到问题会出在这里。
    add esp,0x80000000

    jmp [0x80040004]

; ==============================================================================
; EAX 为读取的扇区数
; DS:EBX 为读取到内存的地址
read_hdd32:
    %include "read_hdd32.inc"
    ret

;-------------------------------------------------------------------------------
    pgdt dw 0
         dd 0x00008000     ;GDT的物理/线性地址
;-------------------------------------------------------------------------------
    times 510-($-$$) db 0
    dw 0xaa55
