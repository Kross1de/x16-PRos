@echo off 

set NASM_PATH="C:\Program Files\NASM/nasm.exe" :: тут ваш путь
set QEMU_PATH="C:\Program Files\qemu\qemu-system-i386.exe" :: тут туже

%NASM_PATH% -f bin boot.asm -o boot.bin
%NASM_PATH% -f bin kernel.asm -o kernel.bin

copy /b boot.bin + kernel.bin xorisos.img

%QEMU_PATH% -fda xorisos.img

pause 
