#!/bin/bash

#Platform :##########################################
[ -z $TARGET_ARCH ] && export TARGET_ARCH="arm32"
[ -z $TARGET_NAME ] && TARGET_NAME="opipc2"
[ -z $DISTRO ] && export DISTRO="centos-7"
[ -z $TARGET_BUILD_NAME ] && TARGET_BUILD_NAME="$TARGET_ARCH-$TARGET_NAME"

#Wrokspace :##########################################
[ -z $WORKSPACE ] && WORKSPACE="$(realpath $(dirname $(realpath $0)))"
echo "$(realpath $0)"
echo "$(dirname $(realpath $0))"
echo "$(realpath $(dirname $(realpath $0)))"
[ -z $DL_DIR ] && export DL_DIR="$WORKSPACE/../dl"
[ -z $IMAGES_DIR ] && export IMAGES_DIR="$WORKSPACE/images-$TARGET_BUILD_NAME"
[ -z $BUILD_DIR ] && export BUILD_DIR="$WORKSPACE/$DISTRO-$TARGET_BUILD_NAME"

[ ! -d $DL_DIR ] && mkdir $DL_DIR
[ ! -d $BUILD_DIR ] && mkdir $BUILD_DIR


if [[ "$DISTRO-$TARGET_ARCH" == "centos-7-arm32" ]]; then
   $WORKSPACE/scripts/01-centos-7-arm32-rootfs.sh
elif [[ "$DISTRO-$TARGET_ARCH" == "centos-7-arm64" ]]; then
   $WORKSPACE/scripts/01-centos-7-arm64-rootfs.sh
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-18.04-arm32" ]]; then
   $WORKSPACE/scripts/02-ubuntu-18.04-arm32-rootfs.sh
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-18.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-18.04-arm64-rootfs.sh
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-14.04-arm32" ]]; then
   $WORKSPACE/scripts/02-ubuntu-14.04-arm32-rootfs.sh
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-14.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-14.04-arm64-rootfs.sh
else
   echo "Invalid DISTRO: $DISTRO-$TARGET_ARCH"
   exit 0
fi

#$WORKSPACE/scripts/03-sysroot-target-build.sh

