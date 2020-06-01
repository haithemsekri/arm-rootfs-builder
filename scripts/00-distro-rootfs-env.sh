#!/bin/bash

source $(dirname $(realpath $0))/00-distro-common-env.sh

[ -z $DISTRO_NAME ] && DISTRO_NAME="$DISTRO-$TARGET_ARCH"
[ -z $DISTRO_SIZE_MB ] && DISTRO_SIZE_MB=2048
[ -z $EXT_FS_TYPE ]    && EXT_FS_TYPE="ext3"
[ -z $MKFS_CMD ]       && MKFS_CMD="mkfs.$EXT_FS_TYPE"

[ -z $ROOTFS_BASE_DISK ] && ROOTFS_BASE_DISK="$BUILD_DIR/$DISTRO_NAME-base.$EXT_FS_TYPE"
[ -z $ROOTFS_BASE_TAR ]  && ROOTFS_BASE_TAR="$BUILD_DIR/$DISTRO_NAME-base.tar.gz"
[ -z $ROOTFS_TARGET_DISK ] && ROOTFS_TARGET_DISK="$ROOTFS_BASE_DISK"
[ -z $SYSROOT_TARGET_TAR ]  && export SYSROOT_TARGET_TAR="$BUILD_DIR/target-sysroot.tar.gz"