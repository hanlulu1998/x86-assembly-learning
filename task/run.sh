nasm -f bin boot32.asm -I make_seg_descriptor.inc -o boot32.bin
nasm -f bin core.asm -I make_seg_descriptor.inc -I read_hdd32.inc -o core.bin
nasm -f bin user_program.asm -o user_program.bin
dd if=boot32.bin of=disk.img bs=512 seek=0 conv=notrunc
dd if=core.bin of=disk.img bs=512 seek=1 conv=notrunc
dd if=user_program.bin of=disk.img bs=512 seek=50 conv=notrunc
qemu-system-x86_64 -drive format=raw,file=disk.img