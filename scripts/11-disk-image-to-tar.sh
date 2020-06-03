#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

SRC_DISK_PATH="$(realpath $1)"
DEST_TAR_PATH=$2
TMP_DIR="$BUILD_DIR/disk-image-to-tar.tmp"

[ ! -e "$SRC_DISK_PATH" ] &&  echo "Invalid arg1 for source image file" && exit 1
[ -z $DEST_TAR_PATH ] &&  echo "Invalid arg2 for destination tar file" && exit 1
[ ! -d $TMP_DIR ] && mkdir -p $TMP_DIR

sudo umount $TMP_DIR 2>/dev/null
sudo mount -o loop $SRC_DISK_PATH $TMP_DIR
sync
MTAB_ENTRY="$(mount | egrep "$SRC_DISK_PATH" | egrep "$TMP_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $TMP_DIR  && exit 1

echo "Tar: $TMP_DIR"
cd $TMP_DIR
sudo tar --exclude="lost+found" -czf $DEST_TAR_PATH .
sudo chmod 666 $DEST_TAR_PATH
cd -

echo "Cleanup: $TMP_DIR"
sudo umount $TMP_DIR
rm -rf $TMP_DIR &> /dev/null
