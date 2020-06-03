#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

SRC_TAR_FILE=$1
DEST_DISK_FILE=$2
DEST_DISK_SIZE=$3
TMP_DIR="$BUILD_DIR/tar-to-disk-image.tmp"

[ ! -f $SRC_TAR_FILE ] &&  echo "Invalid arg1 for source tar file" && exit 1
[ -z $DEST_DISK_FILE ] &&  echo "Invalid arg2 for destination disk file" && exit 1
[ -z $DEST_DISK_SIZE ] &&  echo "Invalid arg3 for destination file size in Mega" && exit 1
[ ! -d $TMP_DIR ] && mkdir -p $TMP_DIR

dd if=/dev/zero of=$DEST_DISK_FILE bs=1M count=$DEST_DISK_SIZE
sync
$MKFS_CMD $DEST_DISK_FILE

sudo umount $TMP_DIR 2>/dev/null
sudo mount -o loop $DEST_DISK_FILE $TMP_DIR
MTAB_ENTRY="$(mount | egrep "$DEST_DISK_FILE" | egrep "$TMP_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $TMP_DIR  && exit 1
sudo tar -xzf $SRC_TAR_FILE -C $TMP_DIR
sync
sudo umount $TMP_DIR
e2fsck -f -y $DEST_DISK_FILE
rm -rf $TMP_DIR
