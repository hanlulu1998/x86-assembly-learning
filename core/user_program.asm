user_data_lba_start equ 100
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
import_sym_table_end:

header_end:

; ============================================================================
; 数据段
section data vstart=0
    buffer times 1024 db 0
    message1 db 0x0d,0x0a,0x0d,0x0a
             db '**********User program is runing**********'
             db 0x0d,0x0a,0
    message2 db '  Disk data:',0x0d,0x0a,0

    message3 db 0x0d,0x0a,0x0d,0x0a
             db '  Sreg info: ',0x0d,0x0a,0
    crlf db 0x0d,0x0a,0
    ds_label db '  DS: ',0
    ss_label db '  SS: ',0
    es_label db '  ES: ',0
    fs_label db '  FS: ',0
    gs_label db '  GS: ',0
    cs_label db '  CS: ',0
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
    mov eax, ds
    mov fs, eax

    mov ss, [fs:stack_segment_addr]
    mov esp, stack_end

    mov ds, [fs:data_segment_addr]

    mov ebx, message1
    call far [fs:print_string]

    mov eax, user_data_lba_start
    mov ebx, buffer
    call far [fs:read_hdd32]

    mov ebx, message2
    call far [fs:print_string]

    mov ebx, buffer
    call far [fs:print_string]

    mov ebx, message3
    call far [fs:print_string]

    mov ebx, ds_label
    mov edx, ds
    call print_reg

    mov ebx, es_label
    mov edx, es
    call print_reg

    mov ebx, fs_label
    mov edx, fs
    call print_reg

    mov ebx, ss_label
    mov edx, ss
    call print_reg

    mov ebx, cs_label
    mov edx, cs
    call print_reg

    call far [fs:terminate_program]


print_reg:
    call far [fs:print_string]
    call far [fs:print_dw_hex]
    mov ebx, crlf
    call far [fs:print_string]
    ret

code_end:

;===============================================================================
section trail
program_end:






