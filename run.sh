#! /bin/bash

#qemu-system-i386 -fda fdisk.img -hda vm/disk.img -boot order=a
qemu-system-i386 -fda fdisk.img -hda disk1.img -boot order=a
