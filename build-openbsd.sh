#!/bin/sh

# This script assembles the OpenSoftware-World OS (MikeOSBased) bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on OpenBSD)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files


echo "Experimental OpenBSD build script..."


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' to switch to root"
	exit
fi


if [ ! -e disk_images/opensoftware_world_os_mikeosbased.flp ]
then
	echo ">>> Creating new OpenSoftware-World OS floppy image..."
	dd if=/dev/zero of=disk_images/opensoftware_world_os_mikeosbased.flp bs=512 count=2880 || exit
	vnconfig vnd3 disk_images/opensoftware_world_os_mikeosbased.flp && newfs_msdos -f 1440 vnd3c && vnconfig -u vnd3 || exit
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

dd conv=notrunc if=source/bootload/bootload.bin of=disk_images/opensoftware_world_os_mikeosbased.flp || exit


echo ">>> Copying OpenSoftware-World OS kernel and programs..."

rm -rf tmp-loop
vnconfig vnd3 disk_images/opensoftware_world_os_mikeosbased.flp || exit

mkdir tmp-loop && mount -t msdos /dev/vnd3c tmp-loop && cp Kernel/kernel.bin tmp-loop/

cp Apps/*.bin Apps/*.bas Apps/sample.pcx Apps/vedithlp.txt Apps/gen.4th Apps/hello.512 tmp-loop

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

vnconfig -u vnd3 || exit
rm -rf tmp-loop


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/opensoftware_world_os_mikeosbased.iso
mkisofs -quiet -V 'OpenSoftware-World OS' -r -J -o disk_images/opensoftware_world_os_mikeosbased.iso -b opensoftware_world_os_mikeosbased.flp disk_images/ || exit

echo '>>> Done!'

