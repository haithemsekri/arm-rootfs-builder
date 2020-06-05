#!/bin/bash
source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

DISK_IMAGE_PATH="$(realpath $1)"
SIZE_TO_ADD=$2
[ ! -f $DISK_IMAGE_PATH ] &&  echo "Invalid arg1 for image file" && exit 1
[ -z $SIZE_TO_ADD ] &&  echo "Invalid arg2 for size to extend in Mega" && exit 1
TMP_DIR="$BUILD_DIR/extend-disk-image-size.tmp"

dd if=/dev/zero bs=1M count=$SIZE_TO_ADD >> $DISK_IMAGE_PATH
[ ! -d $TMP_DIR ] && mkdir -p $TMP_DIR
umount $TMP_DIR 2>/dev/null
e2fsck -f -y $DISK_IMAGE_PATH
mount -o loop $DISK_IMAGE_PATH $TMP_DIR
MTAB_ENTRY="$(mount | egrep "$DISK_IMAGE_PATH on $TMP_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $TMP_DIR && exit 1
LOOP_DEV=$(findmnt -n -o SOURCE --target $TMP_DIR)
[ ! -z "$LOOP_DEV" ] && echo "Resizing Image by $SIZE_TO_ADD MB" && resize2fs $LOOP_DEV
df -h $TMP_DIR
umount $TMP_DIR
rm -rf $TMP_DIR
