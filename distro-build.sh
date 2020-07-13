#!/bin/bash

#Platform :##########################################
[ -z $1 ] && echo "Invalid arg1 for platform name" && exit 1
[ -z $2 ] && echo "Invalid arg2 for distro name" && exit 1
[ -z $3 ] && echo "Invalid arg3 for platform arch" && exit 1

export TARGET_NAME="$1"
export DISTRO="$2"
export TARGET_ARCH="$3"
EXTRA_ARGS="$4 $5 $6"

#Wrokspace :##########################################
[ -z $TARGET_BUILD_NAME ] && TARGET_BUILD_NAME="$TARGET_ARCH-$TARGET_NAME"
[ -z $WORKSPACE ] && WORKSPACE="$(realpath $(dirname $(realpath $0)))"
[ -z $DL_DIR ] && export DL_DIR="$WORKSPACE/dl"
[ -z $BUILD_DIR ] && export BUILD_DIR="$WORKSPACE/$DISTRO-$TARGET_BUILD_NAME"
[ ! -d $DL_DIR ] && mkdir $DL_DIR
[ ! -d $BUILD_DIR ] && mkdir $BUILD_DIR


if [[ "$DISTRO-$TARGET_ARCH" == "centos-7-arm32" ]]; then
   $WORKSPACE/scripts/01-centos-7-arm32-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "centos-7-arm64" ]]; then
   $WORKSPACE/scripts/01-centos-7-arm64-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-18.04-arm32" ]]; then
   $WORKSPACE/scripts/02-ubuntu-18.04-arm32-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-14.04-arm32" ]]; then
   $WORKSPACE/scripts/02-ubuntu-14.04-arm32-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-14.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-14.04-arm64-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-16.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-16.04-arm64-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-18.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-18.04-arm64-rootfs.sh $EXTRA_ARGS
elif [[ "$DISTRO-$TARGET_ARCH" == "ubuntu-20.04-arm64" ]]; then
   $WORKSPACE/scripts/02-ubuntu-20.04-arm64-rootfs.sh $EXTRA_ARGS
else
   echo "Invalid DISTRO: $DISTRO-$TARGET_ARCH"
   exit 0
fi


