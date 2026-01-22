nasm -f bin $1.asm -o $1.bin
qemu-system-x86_64 -drive format=raw,file=$1.bin
