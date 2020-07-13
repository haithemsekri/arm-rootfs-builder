#!/bin/bash

[ ! -f $ROOTFS_DISK_PATH ] &&  echo "Invalid arg1 for image disk" && exit 1

RTFS_MNT_DIR="$BUILD_DIR/chroot-run-shell.tmp"
[ ! -d $RTFS_MNT_DIR ] && mkdir -p $RTFS_MNT_DIR
umount $RTFS_MNT_DIR 2>/dev/null
mount -o loop $ROOTFS_DISK_PATH $RTFS_MNT_DIR
MTAB_ENTRY="$(mount | egrep "$ROOTFS_DISK_PATH" | egrep "$RTFS_MNT_DIR")"
[ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $RTFS_MNT_DIR  && exit 1

chroot_mount_pseudo_fs () {
   mkdir ${RTFS_MNT_DIR}/proc ${RTFS_MNT_DIR}/dev ${RTFS_MNT_DIR}/dev/pts ${RTFS_MNT_DIR}/sys ${RTFS_MNT_DIR}/tmp 2>/dev/null
   mount -o bind /proc    ${RTFS_MNT_DIR}/proc
   mount -o bind /dev     ${RTFS_MNT_DIR}/dev
   mount -o bind /dev/pts ${RTFS_MNT_DIR}/dev/pts
   mount -o bind /sys     ${RTFS_MNT_DIR}/sys
   mount -o bind /tmp     ${RTFS_MNT_DIR}/tmp
   mount -o bind /tmp     ${RTFS_MNT_DIR}/run
}

if_mounted_umount() {
   MTAB_ENTRY="$(mount | egrep "$1")"
   [ ! -z "$MTAB_ENTRY" ] && echo "umount $1" && umount $1
   MTAB_ENTRY="$(mount | egrep "$1")"
   [ ! -z "$MTAB_ENTRY" ] && echo "force umount $1" && umount -f -l $1
}

chroot_umount_pseudo_fs () {
   sync
   RUNNING_PROCS="$(lsof $RTFS_MNT_DIR 2>/dev/null | grep "root  rtd")"
   [ ! -z "$RUNNING_PROCS" ] && echo "Stop Pids:" && echo $RUNNING_PROCS && lsof $RTFS_MNT_DIR 2>/dev/null | grep "root  rtd" | awk '{print $2}' | xargs kill -9
   if_mounted_umount ${RTFS_MNT_DIR}/dev/pts
   if_mounted_umount ${RTFS_MNT_DIR}/dev
   if_mounted_umount ${RTFS_MNT_DIR}/proc
   if_mounted_umount ${RTFS_MNT_DIR}/sys
   if_mounted_umount ${RTFS_MNT_DIR}/tmp
   if_mounted_umount ${RTFS_MNT_DIR}/run
}

cleanup_on_exit () {
   echo "cleanup_on_exit"
   chroot_umount_pseudo_fs
   if_mounted_umount ${RTFS_MNT_DIR}
   rm -rf ${RTFS_MNT_DIR}
}

chroot_run_script () {
   CHROOT_SCRIPT_PATH=$1
   [ ! -f $CHROOT_SCRIPT_PATH ] &&  echo "Invalid arg1 for script to run in chroot" && exit 1
   cp $CHROOT_SCRIPT_PATH $RTFS_MNT_DIR/chroot-script.sh
   chmod 755 $RTFS_MNT_DIR/chroot-script.sh
   chroot $RTFS_MNT_DIR /usr/bin/env -i /bin/bash -l /chroot-script.sh
   rm -rf $RTFS_MNT_DIR/chroot-script.sh
}

trap cleanup_on_exit EXIT

if [ "$TARGET_ARCH" == "arm64" ]; then
   [ ! -f $RTFS_MNT_DIR/usr/bin/qemu-aarch64-static ] && cp /usr/bin/qemu-aarch64-static $RTFS_MNT_DIR/usr/bin/qemu-aarch64-static
elif [ "$TARGET_ARCH" == "arm32" ]; then
   [ ! -f $RTFS_MNT_DIR/usr/bin/qemu-arm-static ] && cp /usr/bin/qemu-arm-static $RTFS_MNT_DIR/usr/bin/qemu-arm-static
fi

chroot_mount_pseudo_fs
