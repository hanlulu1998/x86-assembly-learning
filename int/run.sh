nasm -f bin boot32.asm -I make_seg_descriptor.inc -o boot32.bin
nasm -f bin core.asm -I make_seg_descriptor.inc -I read_hdd32.inc -o core.bin
nasm -f bin user_program1.asm -o user_program1.bin
nasm -f bin user_program2.asm -o user_program2.bin
dd if=boot32.bin of=disk.img bs=512 seek=0 conv=notrunc
dd if=core.bin of=disk.img bs=512 seek=1 conv=notrunc
dd if=user_program1.bin of=disk.img bs=512 seek=50 conv=notrunc
dd if=user_program2.bin of=disk.img bs=512 seek=100 conv=notrunc
qemu-system-x86_64 -drive format=raw,file=disk.img