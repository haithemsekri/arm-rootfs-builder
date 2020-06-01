#!/bin/bash

[ ! -f $ROOTFS_DISK_PATH ] &&  echo "Invalid arg1 for image disk" && exit 0

RTFS_MNT_DIR="$BUILD_DIR/chroot-run-shell.tmp"
[ ! -d $RTFS_MNT_DIR ] && mkdir -p $RTFS_MNT_DIR
sudo umount $RTFS_MNT_DIR 2>/dev/null
sudo mount -o loop $ROOTFS_DISK_PATH $RTFS_MNT_DIR
MTAB_ENTRY="$(mount | egrep "$ROOTFS_DISK_PATH" | egrep "$RTFS_MNT_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $RTFS_MNT_DIR  && exit 0

chroot_mount_pseudo_fs () {
   sudo mkdir ${RTFS_MNT_DIR}/proc ${RTFS_MNT_DIR}/dev ${RTFS_MNT_DIR}/dev/pts ${RTFS_MNT_DIR}/sys ${RTFS_MNT_DIR}/tmp 2>/dev/null
   sudo mount -o bind /proc ${RTFS_MNT_DIR}/proc
   sudo mount -o bind /dev ${RTFS_MNT_DIR}/dev
   sudo mount -o bind /dev/pts ${RTFS_MNT_DIR}/dev/pts
   sudo mount -o bind /sys ${RTFS_MNT_DIR}/sys
   sudo mount -o bind /tmp ${RTFS_MNT_DIR}/tmp
}

chroot_umount_pseudo_fs () {
   sudo umount ${RTFS_MNT_DIR}/dev/* 2>/dev/null
   sudo umount ${RTFS_MNT_DIR}/proc ${RTFS_MNT_DIR}/dev/pts ${RTFS_MNT_DIR}/dev ${RTFS_MNT_DIR}/sys ${RTFS_MNT_DIR}/tmp 2>/dev/null
   sudo umount ${RTFS_MNT_DIR}/* 2>/dev/null

   sudo umount -f -l ${RTFS_MNT_DIR}/*/* 2>/dev/null
   sudo umount -f -l ${RTFS_MNT_DIR}/* 2>/dev/null
}

cleanup_on_exit () {
   MTAB_ENTRY="$(mount | egrep "$ROOTFS_DISK_PATH" | egrep "$RTFS_MNT_DIR")"
   if [ ! -z "$MTAB_ENTRY" ]; then
      echo "cleanup_on_exit"
      sync
      chroot_umount_pseudo_fs
      sudo chroot $RTFS_MNT_DIR /bin/bash -c "chown -R root:root /; rm -rf /tmp/*; rm -rf /sys/*; rm -rf /proc/*"
      sudo umount  $RTFS_MNT_DIR 2>/dev/null
      sudo umount -f -l $RTFS_MNT_DIR 2>/dev/null
      rm -rf $RTFS_MNT_DIR
   fi
}

chroot_run_script () {
   CHROOT_SCRIPT_PATH=$1
   [ ! -f $CHROOT_SCRIPT_PATH ] &&  echo "Invalid arg1 for script to run in chroot" && exit 0
   sudo cp $CHROOT_SCRIPT_PATH $RTFS_MNT_DIR/chroot-script.sh
   sudo chmod 755 $RTFS_MNT_DIR/chroot-script.sh
   sudo chroot $RTFS_MNT_DIR /bin/bash /chroot-script.sh
   sudo rm -rf $RTFS_MNT_DIR/chroot-script.sh
}

trap cleanup_on_exit EXIT

if [ "$TARGET_ARCH" == "arm64" ]; then
   [ ! -f $RTFS_MNT_DIR/usr/bin/qemu-aarch64-static ] && sudo cp /usr/bin/qemu-aarch64-static $RTFS_MNT_DIR/usr/bin/qemu-aarch64-static
elif [ "$TARGET_ARCH" == "arm32" ]; then
   [ ! -f $RTFS_MNT_DIR/usr/bin/qemu-arm-static ] && sudo cp /usr/bin/qemu-arm-static $RTFS_MNT_DIR/usr/bin/qemu-arm-static
fi

chroot_mount_pseudo_fs
