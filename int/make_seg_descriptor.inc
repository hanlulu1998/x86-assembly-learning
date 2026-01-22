    mov edx, eax

    ; 完成低32位描述符（EAX）的内容，低16为段界限，高16位基地址
    shl eax, 16
    or ax,bx

    ; 装配基址的31~24和23~16
    and edx, 0xffff0000
    rol edx, 8
    bswap edx

    ; 段界限的高4位
    xor bx, bx
    or edx, ebx

    ; 完成属性装配
    or edx, ecx