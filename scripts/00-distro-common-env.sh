#!/bin/bash

[ -z $DL_DIR ] && echo "DL_DIR: not defined" && exit 1
[ -z $BUILD_DIR ] && echo "BUILD_DIR: not defined" && exit 1
[ -z $TARGET_ARCH ] && echo "TARGET_ARCH: not defined" && exit 1
[ -z $DISTRO ] && echo "DISTRO: not defined" && exit 1

echo "==============================================================="
echo "DL_DIR: $DL_DIR"
echo "BUILD_DIR: $BUILD_DIR"
echo "TARGET_ARCH: $TARGET_ARCH"
echo "DISTRO: $DISTRO"
echo "==============================================================="

SCRIPTS_DIR="$(realpath $(dirname $(realpath $0))/..)/scripts"

[ ! -d $DL_DIR ] && mkdir $DL_DIR
[ ! -d $BUILD_DIR ] && mkdir $BUILD_DIR
