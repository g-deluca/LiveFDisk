#! /bin/bash

clear

nasm -f bin loader.s -o loader.bin
nasm -f bin fdisk.s -o fdisk.bin
dd if=loader.bin of=fdisk.img
dd if=fdisk.bin bs=512 seek=1 of=fdisk.img
