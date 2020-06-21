#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

echo "==============================================================="
echo "DL_DIR:      $DL_DIR"
echo "BUILD_DIR:   $BUILD_DIR"
echo "TARGET_ARCH: $TARGET_ARCH"
echo "DISTRO:      $DISTRO"
echo "==============================================================="

[ -z $ROOTFS_DL_TAR ] && ROOTFS_DL_TAR="$DL_DIR/$(basename $ROOTFS_DL_URL)"
[ ! -f $ROOTFS_DL_TAR ] && wget $ROOTFS_DL_URL -O $ROOTFS_DL_TAR
[ ! -f $ROOTFS_DL_TAR ] && echo "$ROOTFS_DL_TAR : file not found"

build_base_rootfs_disk() {
if [ -f $ROOTFS_BASE_TAR ]; then
   echo "Based on: $ROOTFS_BASE_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_BASE_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB
else
   echo "Based on: $ROOTFS_DL_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_DL_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB
   sync

   export ROOTFS_DISK_PATH=$ROOTFS_BASE_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   cp $SCRIPTS_DIR/14-cross-build-env.sh $RTFS_MNT_DIR/14-cross-build-env.sh
   chmod 755 $RTFS_MNT_DIR/14-cross-build-env.sh

   if [ ! -z "$BASE_ROOTFS_PRE_CHROOT_SCRIPT" ]; then
      echo "Run : BASE_ROOTFS_PRE_CHROOT_SCRIPT"
      echo "$BASE_ROOTFS_PRE_CHROOT_SCRIPT" > "$BUILD_DIR/rootfs-script.sh"
      chmod 755 $BUILD_DIR/rootfs-script.sh
      $BUILD_DIR/rootfs-script.sh "$RTFS_MNT_DIR"
   fi

   if [ ! -z "$BASE_ROOTFS_CHROOT_SCRIPT" ]; then
      echo "Run : BASE_ROOTFS_CHROOT_SCRIPT"
      echo "$BASE_ROOTFS_CHROOT_SCRIPT" > "$BUILD_DIR/rootfs-script.sh"
      chmod 755 "$BUILD_DIR/rootfs-script.sh"
      chroot_run_script "$BUILD_DIR/rootfs-script.sh"
   fi

   if [ ! -z "$BASE_ROOTFS_POST_CHROOT_SCRIPT" ]; then
      echo "Run : BASE_ROOTFS_POST_CHROOT_SCRIPT"
      echo "$BASE_ROOTFS_POST_CHROOT_SCRIPT" > "$BUILD_DIR/rootfs-script.sh"
      chmod 755 "$BUILD_DIR/rootfs-script.sh"
      $BUILD_DIR/rootfs-script.sh "$RTFS_MNT_DIR"
   fi

   sync
   rm -rf $RTFS_MNT_DIR/14-cross-build-env.sh
   cleanup_on_exit
   rm -rf $BUILD_DIR/rootfs-script.sh
fi
}

build_target_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   cp $ROOTFS_BASE_DISK $ROOTFS_TARGET_DISK

   export ROOTFS_DISK_PATH=$ROOTFS_TARGET_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh

   if [ ! -z "$TARGET_ROOTFS_PRE_CHROOT_SCRIPT" ]; then
      echo "Run : TARGET_ROOTFS_PRE_CHROOT_SCRIPT"
      echo "$TARGET_ROOTFS_PRE_CHROOT_SCRIPT" > $BUILD_DIR/rootfs-script.sh
      chmod 755 $BUILD_DIR/rootfs-script.sh
      $BUILD_DIR/rootfs-script.sh "$RTFS_MNT_DIR"
   fi

   if [ ! -z "$TARGET_ROOTFS_CHROOT_SCRIPT" ]; then
      echo "Run : TARGET_ROOTFS_CHROOT_SCRIPT"
      echo "$TARGET_ROOTFS_CHROOT_SCRIPT" > $BUILD_DIR/rootfs-script.sh
      chmod 755 $BUILD_DIR/rootfs-script.sh
      chroot_run_script "$BUILD_DIR/rootfs-script.sh"
   fi

   if [ ! -z "$TARGET_ROOTFS_POST_CHROOT_SCRIPT" ]; then
      echo "Run : TARGET_ROOTFS_POST_CHROOT_SCRIPT"
      echo "$TARGET_ROOTFS_POST_CHROOT_SCRIPT" > $BUILD_DIR/rootfs-script.sh
      chmod 755 $BUILD_DIR/rootfs-script.sh
      $BUILD_DIR/rootfs-script.sh "$RTFS_MNT_DIR"
   fi

   sync
   cleanup_on_exit
   rm -rf $BUILD_DIR/rootfs-script.sh
}

backup_base_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   $SCRIPTS_DIR/11-disk-image-to-tar.sh $ROOTFS_BASE_DISK $ROOTFS_BASE_TAR
   chmod 666 $ROOTFS_BASE_TAR
}

if [ "$1" == "--rebuild" ]; then
   echo "delete $ROOTFS_BASE_DISK"
   rm -rf "$ROOTFS_BASE_DISK"
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf "$ROOTFS_TARGET_DISK"
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
[ ! -f $ROOTFS_BASE_TAR ] && echo "$ROOTFS_BASE_TAR : file not found" && exit 1
chmod 666 $ROOTFS_BASE_TAR

if [ "$1" == "--build-target" ]; then
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf "$ROOTFS_TARGET_DISK"
   echo "Build: $ROOTFS_TARGET_DISK"
   build_target_rootfs_disk
   echo "target disk: $ROOTFS_TARGET_DISK"
   chmod 666 $ROOTFS_TARGET_DISK
fi

