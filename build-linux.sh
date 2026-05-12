#!/bin/sh

# This script assembles the MikeOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/opensoftware_world_os_mikeosbased.flp')


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


if [ ! -e disk_images/opensoftware_world_os_mikeosbased.flp ]
then
	echo ">>> Creating new OpenSoftware-World OS floppy image..."
	mkdosfs -C disk_images/opensoftware_world_os_mikeosbased.flp 1440 || exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o Boot/boot.bin Boot/boot.asm || exit


echo ">>> Assembling OpenSoftware-World OS kernel..."

cd Kernel
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..


echo ">>> Assembling programs..."

cd Apps

for i in *.asm
do
	nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.app || exit
done

cd ..


echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=Boot/boot.bin of=disk_images/opensoftware_world_os_mikeosbased.flp || exit


echo ">>> Copying OpenSoftware-World OS kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/opensoftware_world_os_mikeosbased.flp tmp-loop && cp Kernel/kernel.bin tmp-loop/

cp Apps/*.app Apps/*.bas Apps/sample.pcx Apps/vedithlp.txt Apps/gen.4th Apps/hello.512 tmp-loop

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/opensoftware_world_os_mikeosbased.iso
mkisofs -quiet -V 'OpenSoftware-World OS' -input-charset iso8859-1 -o disk_images/opensoftware_world_os_mikeosbased.iso -b opensoftware_world_os_mikeosbased.flp disk_images/ || exit

echo '>>> Done!'

