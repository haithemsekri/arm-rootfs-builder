#!/bin/bash

[ -z $DL_DIR ]      && echo "DL_DIR: not defined" && exit 1
[ -z $BUILD_DIR ]   && echo "BUILD_DIR: not defined" && exit 1
[ -z $TARGET_ARCH ] && echo "TARGET_ARCH: not defined" && exit 1
[ -z $DISTRO ]      && echo "DISTRO: not defined" && exit 1

[ -z $DISTRO_NAME ]    && export DISTRO_NAME="$DISTRO-$TARGET_ARCH"
[ -z $DISTRO_SIZE_MB ] && export DISTRO_SIZE_MB=1536
[ -z $EXT_FS_TYPE ]    && export EXT_FS_TYPE="ext3"
[ -z $MKFS_CMD ]       && export MKFS_CMD="mkfs.$EXT_FS_TYPE"

[ -z $ROOTFS_BASE_DISK ]    && export ROOTFS_BASE_DISK="$BUILD_DIR/$DISTRO_NAME-base.$EXT_FS_TYPE"
[ -z $ROOTFS_BASE_TAR ]     && export ROOTFS_BASE_TAR="$BUILD_DIR/$DISTRO_NAME-base.tar.gz"
[ -z $ROOTFS_TARGET_DISK ]  && export ROOTFS_TARGET_DISK="$BUILD_DIR/$DISTRO_NAME-target.$EXT_FS_TYPE"
[ -z $SYSROOT_TARGET_TAR ]  && export SYSROOT_TARGET_TAR="$BUILD_DIR/target-sysroot.tar.gz"
