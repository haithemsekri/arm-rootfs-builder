#!/bin/bash

[ ! -b $1 ] &&  echo "Invalid arg1 for destination device file" && exit 1

DEVICE=$1

umount $DEVICE 2>/dev/null
umount -f -l "$DEVICE"1 2>/dev/null
umount -f -l "$DEVICE"2 2>/dev/null
umount -f -l "$DEVICE"3 2>/dev/null
umount -f -l "$DEVICE"4 2>/dev/null


dd if=/dev/zero of=$DEVICE bs=1M count=1 status=progress

dd if=loader of=$DEVICE status=progress
sync
sleep 0.1

dd if=bootfs of="$DEVICE"1 status=progress
e2fsck -y -f "$DEVICE"1
resize2fs "$DEVICE"1

dd if=rootfs of="$DEVICE"2 status=progress
e2fsck -y -f "$DEVICE"2
resize2fs "$DEVICE"2
