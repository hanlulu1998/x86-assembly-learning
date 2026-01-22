interrupt_number equ 0x70

section header align=16 vstart=0
    program_length dd program_end
    code_entry dw start
               dd section.code.start
    segment_table_length dw (header_end - segment_table_begin) / 4
    segment_table_begin:
    code_segment_addr dd section.code.start
    data_segment_addr dd section.data.start
    stack_segment_addr dd section.stack.start
header_end:

section code align=16 vstart=0

rtc_int0x70:
    push ax
    push bx
    push cx
    push dx
    push es
.wait_uip:
    ; 读取寄存器A的值
    mov al, 0x0a
    ; 阻断NMI
    or al, 0x80

    out 0x70, al
    in al, 0x71

    test al, 0x80
    ; 等待UIP为0，保证结果有效
    jnz .wait_uip

    ; 读秒
    mov al, 0x00
    or al, 0x80
    out 0x70, al
    in al, 0x71
    push ax

    ; 读分钟
    mov al, 0x02
    or al, 0x80
    out 0x70, al
    in al, 0x71
    push ax

    ; 读小时
    mov al, 0x04
    or al, 0x80
    out 0x70, al
    in al, 0x71
    push ax

    ; 读寄存器C，清零中断标志位
    mov al, 0x0c
    out 0x70, al
    in al, 0x71

    mov ax, 0xb800
    mov es, ax

    ; 从12行36列开始显示时间信息
    mov bx, 12*160+36*2

    pop ax
    call bcd_to_ascii
    mov [es:bx], ah
    mov [es:bx+2], al

    mov al, ':'
    mov [es:bx+4], al
    not byte [es:bx+5]

    pop ax
    call bcd_to_ascii
    mov [es:bx+6], ah
    mov [es:bx+8], al

    mov al, ':'
    mov [es:bx+10], al
    not byte [es:bx+11]

    pop ax
    call bcd_to_ascii
    mov [es:bx+12], ah
    mov [es:bx+14], al

    ; 发送中断结束信号到主从片
    mov al, 0x20
    out 0xa0, al
    out 0x20, al

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    iret

; 输入: AL为BCD码
; 输出，AX为ASCII码
bcd_to_ascii:
    ; 将al拆分成两个4bit数
    mov ah,al
    and al,0x0f
    add al,'0'

    shr ah, 4
    and ah, 0x0f
    add ah, '0'
    ret

start:
    mov ax, [stack_segment_addr]
    mov ss, ax
    mov sp, stack_top
    mov ax, [data_segment_addr]
    mov ds, ax

    mov bx, init_msg
    call print_string

    mov bx, ins_msg
    call print_string

    mov al, interrupt_number
    mov bl, 4
    mul bl
    mov bx, ax

    ; x86关闭中断
    cli

    push es
    ; 设置中断向量
    mov ax, 0x0000
    mov es, ax
    mov word [es:bx], rtc_int0x70
    mov word [es:bx+2], cs
    pop es

    mov al, 0x0b
    or al, 0x80
    out 0x70, al
    ; 设置寄存器B，开启更新结束后中断，BCD码，24小时制
    mov al, 0x12
    out 0x71, al

    mov al, 0x0c
    out 0x70, al
    ; 读寄存器C，清零中断标志位
    in al, 0x71

    in al, 0xa1
    ; 读8259从片的IMR寄存器，bit0为0，允许rtc中断通过
    and al, 0xfe
    out 0xa1, al

    ; x86打开中断
    sti

    mov bx, done_msg
    call print_string

    mov bx, tips_msg
    call print_string

    mov cx, 0xb800
    mov ds, cx
    ; 在屏幕上显示字符 '@'，表示时钟中断正在工作
    mov byte [12*160+33*2], '@'
.idle:
    hlt
    ; 翻转颜色属性
    not byte [12*160+33*2+1]
    jmp .idle

%include "print.inc"

section data align=16 vstart=0
    init_msg db 'RTC Test Program Starting...', 0x0d, 0x0a, 0
    ins_msg db 'Installing RTC interrupt 70H...', 0
    done_msg db 'Done.', 0x0d, 0x0a, 0
    tips_msg db 'Clock interrupts are working.', 0

section stack align=16 vstart=0
    resb 256
stack_top:

section trail
program_end: