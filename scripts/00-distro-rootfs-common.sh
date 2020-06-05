#!/bin/bash

backup_base_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   $SCRIPTS_DIR/11-disk-image-to-tar.sh $ROOTFS_BASE_DISK $ROOTFS_BASE_TAR
   chmod 666 $ROOTFS_BASE_TAR
}

if [ "$1" == "--rebuild" ]; then
   echo -n ""
fi

if [ "$1" == "--clean-rebuild" ]; then
   echo "delete $ROOTFS_BASE_DISK"
   rm -rf "$ROOTFS_BASE_DISK"
   echo "delete $ROOTFS_BASE_TAR"
   rm -rf "$ROOTFS_BASE_TAR"
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf "$ROOTFS_TARGET_DISK"
fi

echo "Building $ROOTFS_BASE_DISK"
[ ! -f $ROOTFS_BASE_DISK ] && build_base_rootfs_disk
[ ! -f $ROOTFS_BASE_DISK ] && echo "$ROOTFS_BASE_DISK : file not found" && exit 1
chmod 666 $ROOTFS_BASE_DISK

echo "Building $ROOTFS_BASE_TAR"
[ ! -f $ROOTFS_BASE_TAR ] && backup_base_rootfs_disk

if [ "$1" == "--build-target" ]; then
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf "$ROOTFS_TARGET_DISK"
   echo "Build: $ROOTFS_TARGET_DISK"
   build_target_rootfs_disk
   echo "target disk: $ROOTFS_TARGET_DISK"
   chmod 666 $ROOTFS_TARGET_DISK
fi

if [ "$1" == "--build-sysroot" ]; then
   $SCRIPTS_DIR/03-sysroot-target-build.sh
fi
