@echo off
echo Build script for Windows
echo.

echo Assembling bootloader...
cd Boot\boot
nasm -O0 -f bin -o boot.bin boot.asm
cd ..

cd Kernel
echo Assembling OpenSoftware-World OS (MikeOSBased) kernel...
nasm -O0 -f bin -o kernel.bin kernel.asm

echo Assembling programs...
cd ..\Apps
 for %%i in (*.asm) do nasm -O0 -f app %%i
 for %%i in (*.bin) do del %%i
 for %%i in (*.) do ren %%i %%i.bin
cd ..

echo Adding bootsector to disk image...
cd disk_images
dd count=2 seek=0 bs=512 if=..\Boot\boot.bin of=.\opensoftware_world_os_mikeosbased.flp
cd ..

echo Mounting disk image...
imdisk -a -f disk_images\opensoftware_world_os_mikeosbased.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy Kernel\kernel.bin b:\
copy Apps\*.app b:\
copy Apps\sample.pcx b:\
copy Apps\vedithlp.txt b:\
copy Apps\gen.4th b:\
copy Apps\hello.512 b:\
copy Apps\*.bas b:\

echo Dismounting disk image...
imdisk -D -m B:

echo Done!
