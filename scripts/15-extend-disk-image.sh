#!/bin/bash
source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

DISK_IMAGE_PATH="$(realpath $1)"
SIZE_TO_ADD=$2
[ ! -f $DISK_IMAGE_PATH ] &&  echo "Invalid arg1 for image file" && exit 0
[ -z $SIZE_TO_ADD ] &&  echo "Invalid arg2 for size to extend in Mega" && exit 0
TMP_DIR="$BUILD_DIR/extend-disk-image-size.tmp"

dd if=/dev/zero bs=1M count=$SIZE_TO_ADD >> $DISK_IMAGE_PATH
[ ! -d $TMP_DIR ] && mkdir -p $TMP_DIR
sudo umount $TMP_DIR 2>/dev/null
sudo e2fsck -f -y $DISK_IMAGE_PATH
sudo mount -o loop $DISK_IMAGE_PATH $TMP_DIR
MTAB_ENTRY="$(mount | egrep "$DISK_IMAGE_PATH on $TMP_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $TMP_DIR && exit 0
LOOP_DEV=$(findmnt -n -o SOURCE --target $TMP_DIR)
[ ! -z "$LOOP_DEV" ] && echo "Resizing Image by $SIZE_TO_ADD MB" && sudo resize2fs $LOOP_DEV
sudo umount $TMP_DIR
rm -rf $TMP_DIR
