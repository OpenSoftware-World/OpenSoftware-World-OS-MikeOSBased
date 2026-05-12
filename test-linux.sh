#!/bin/sh

# This script starts the QEMU PC emulator, booting from the
# OpenSoftware-World OS floppy disk image

qemu-system-i386 -drive format=raw,file=disk_images/opensoftware_world_os_mikeosbased.flp,index=0,if=floppy
