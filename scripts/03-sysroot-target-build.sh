#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ ! -f $ROOTFS_BASE_DISK ] && echo "$ROOTFS_BASE_DISK : file not found"  && exit 1

if [ "$1" == "--rebuild" ]; then
   echo -n ""
fi

if [ "$1" == "--clean-rebuild" ]; then
   echo "delete $SYSROOT_TARGET_TAR"
   rm -rf "$SYSROOT_TARGET_TAR"
fi

if [ ! -d $SYSROOT_TARGET_TAR ]; then
   TMP_DIR="$BUILD_DIR/cross-compiler-setup.tmp"
   [ ! -d $TMP_DIR ] && mkdir -p $TMP_DIR
   umount $TMP_DIR 2>/dev/null
   mount -o loop $ROOTFS_BASE_DISK $TMP_DIR
   MTAB_ENTRY="$(mount | egrep "$ROOTFS_BASE_DISK" | egrep "$TMP_DIR")"
   [ -z "$MTAB_ENTRY" ] &&  echo "Failed to mount disk" && rm -rf $TMP_DIR  && exit 1

   SYSROOT_PATH="$BUILD_DIR/sysroot.tmp"
   mkdir -p $SYSROOT_PATH
   mkdir -p $SYSROOT_PATH/usr
   mkdir -p $SYSROOT_PATH/usr/local/

   [ -d $TMP_DIR/lib  ] && echo "Installing $TMP_DIR/lib ---> $SYSROOT_PATH/"  && cp -r $TMP_DIR/lib $SYSROOT_PATH/
   [ -d $TMP_DIR/include  ] && echo "Installing $TMP_DIR/include ---> $SYSROOT_PATH/"  && cp -r $TMP_DIR/include $SYSROOT_PATH/
   [ -d $TMP_DIR/usr/lib  ] && echo "Installing $TMP_DIR/usr/lib ---> $SYSROOT_PATH/usr/"  && cp -r $TMP_DIR/usr/lib $SYSROOT_PATH/usr/
   [ -d $TMP_DIR/usr/include  ] && echo "Installing $TMP_DIR/usr/include ---> $SYSROOT_PATH/usr/"  && cp -r $TMP_DIR/usr/include $SYSROOT_PATH/usr/
   [ -d $TMP_DIR/usr/local/lib  ] && echo "Installing $TMP_DIR/usr/local/lib ---> $SYSROOT_PATH/usr/local/"  && cp -r $TMP_DIR/usr/local/lib $SYSROOT_PATH/usr/local/
   [ -d $TMP_DIR/usr/local/include  ] && echo "Installing $TMP_DIR/usr/local/include ---> $SYSROOT_PATH/usr/local/"  && cp -r $TMP_DIR/usr/local/include $SYSROOT_PATH/usr/local/
   sync

   cp $SCRIPTS_DIR/03-sysroot-build-env.sh $TMP_DIR/chroot_script.sh
   chmod 755 $TMP_DIR/chroot_script.sh
   chroot $TMP_DIR /bin/bash /chroot_script.sh
   rm -rf $TMP_DIR/chroot_script.sh
   cp $TMP_DIR/sysroot_basic_env.sh $SYSROOT_PATH

   umount $TMP_DIR  2>/dev/null
   umount -f -l $TMP_DIR  2>/dev/null
   rm -rf $TMP_DIR

   cd $SYSROOT_PATH
   tar -czf $SYSROOT_TARGET_TAR .
   cd -
   rm -rf $SYSROOT_PATH
fi


echo "target-sysroot: $SYSROOT_TARGET_TAR"
