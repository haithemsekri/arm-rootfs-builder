#!/bin/bash

[ ! -b $1 ] &&  echo "Invalid arg1 for destination device file" && exit 0

DEVICE=$1

sudo umount $DEVICE 2>/dev/null
sudo umount -f -l "$DEVICE"1 2>/dev/null
sudo umount -f -l "$DEVICE"2 2>/dev/null
sudo umount -f -l "$DEVICE"3 2>/dev/null
sudo umount -f -l "$DEVICE"4 2>/dev/null


sudo dd if=/dev/zero of=$DEVICE bs=1M count=1 status=progress

sudo dd if=loader of=$DEVICE status=progress
sync
sleep 0.1

sudo dd if=bootfs of="$DEVICE"1 status=progress
sudo e2fsck -y -f "$DEVICE"1
sudo resize2fs "$DEVICE"1

sudo dd if=rootfs of="$DEVICE"2 status=progress
sudo e2fsck -y -f "$DEVICE"2
sudo resize2fs "$DEVICE"2
