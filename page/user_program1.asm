; ============================================================================
; 用户程序头
section header vstart=0
    program_length dd program_end

    header_length dd header_end

    code_entry dd start

segment_table_start:
    code_segment_addr dd section.code.start
    code_segment_length dd code_end

    data_segment_addr dd section.data.start
    data_segment_length dd data_end

    stack_segment_addr dd section.stack.start
    stack_segment_length dd stack_end
segment_table_end:

    ; 导入符号条目个数
    import_sym_entity_num dd (header_end-import_sym_table_start)/256 ;#0x24

import_sym_table_start:                                     ;#0x28
    print_string db '@PrintString'
    times 256-($-print_string) db 0

    terminate_program db '@TerminateProgram'
    times 256-($-terminate_program) db 0

    read_hdd32 db '@ReadHDD32'
    times 256-($-read_hdd32) db 0

    print_dw_hex db '@PrintDwordHex'
    times 256-($-print_dw_hex) db 0

    init_task_switch db '@InitTaskSwitch'
    times 256-($-init_task_switch) db 0
import_sym_table_end:

header_end:

; ============================================================================
; 数据段
section data vstart=0
    message1 db 0x0d,0x0a
             db  '[USER TASK1]: '
             db  'I am run at CPL=',
    cpl      db  0
             db  '.',0x0d,0x0a,0


data_end:

; ============================================================================
; 栈段
section stack vstart=0
    times 2048 db 0
stack_end:


[bits 32]
; ============================================================================
; 程序段
section code vstart=0
start:
    ;任务启动时，DS指向头部段，也不需要设置堆栈
    mov eax,ds
    mov fs,eax


    mov ax,[data_segment_addr]
    mov ds,ax

    mov ax,cs
    and al,0000_0011B
    or al,0x30
    mov [cpl],al


.do_print:
    mov ebx, message1
    call far [fs:print_string]
    jmp .do_print

    call far [fs:terminate_program]

code_end:
;===============================================================================
section trail
program_end:






