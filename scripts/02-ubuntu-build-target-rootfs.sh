#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ ! -f $XEN_IMAGE_FILE ] &&  echo "$XEN_IMAGE_FILE not found" && exit 0
[ ! -f $ROOTFS_BASE_DISK ] &&  echo "$ROOTFS_BASE_DISK not found" && exit 0
[ ! -f $KERNEL_DOM0_IMAGE_FILE ] &&  echo "$KERNEL_DOM0_IMAGE_FILE not found" && exit 0

if [ "$1" == "--rebuild" ]; then
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf $ROOTFS_TARGET_DISK
fi

if [ "$1" == "--clean-rebuild" ]; then
   echo "delete $ROOTFS_TARGET_DISK"
   rm -rf $ROOTFS_TARGET_DISK
fi

echo "Building: $ROOTFS_TARGET_DISK"
if [ ! -f $ROOTFS_TARGET_DISK ]; then
   echo "Based on: $ROOTFS_BASE_DISK"

   rm -rf $ROOTFS_TARGET_DISK
   cp $ROOTFS_BASE_DISK $ROOTFS_TARGET_DISK
   sync

   CHROOT_SCRIPT="$BUILD_DIR/chroot-script.sh"
   rm -rf  $CHROOT_SCRIPT

cat <<EOF > $CHROOT_SCRIPT
#!/bin/bash
$XEN_CHROOT_SCRIPT
#apt-get -y remove binutils-aarch64-linux-gnu libc-dev-bin \
#   zlib1g-dev linux-libc-dev libpcre3-dev libc6-dev \
#   make libsqlite3-0 patch \
#   binutils  binutils-common libbinutils libexpat1 libgdbm-compat4 libgdbm5 libmpdec2 libpcre16-3 \
#   gcc-7-base libasan4 libatomic1 libgcc-7-dev libgomp1 libitm1 liblsan0 libncurses5-dev libstdc++-7-dev libsystemd-dev libtinfo-dev libtsan0 libubsan0 uuid-dev \
#   libpcre32-3 libpcrecpp0v5 libreadline7 mime-support readline-common \
#   python3  python3.6 python3.6-minimal libpython3-stdlib libpython3.6-minimal libpython3.6-stdlib  python3-minimal perl libperl5.26 perl-modules-5.26

apt-get -y clean

rm -rf /var/cache/apt
#rm -rf /var/lib/apt
#rm -rf /var/log/apt
#rm /usr/lib/apt/apt.systemd.daily
#rm -rf /usr/include/*
rm -rf /include
#rm -rf /usr/locale
rm -rf /lib/*.a
rm -rf /usr/lib/aarch64-linux-gnu/*.a
#rm -rf /usr/share/*
#rm -rf /share/*
#rm -rf /usr/lib/aarch64-linux-gnu/perl-base
EOF

   export ROOTFS_DISK_PATH=$ROOTFS_TARGET_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   echo "Add Overlays: $KERNEL_DOM0_IMAGE_FILE"
   sudo tar -xzf $KERNEL_DOM0_IMAGE_FILE -C $RTFS_MNT_DIR
   echo "Add Overlays: $XEN_IMAGE_FILE"
   sudo tar -xzf $XEN_IMAGE_FILE -C $RTFS_MNT_DIR
   sudo rsync -avlz  $SCRIPTS_DIR/overlays/  ${RTFS_MNT_DIR}/
   chroot_run_script $CHROOT_SCRIPT
   cd $RTFS_MNT_DIR
   tar -czf $BOOTFS_TARGET_IMAGE boot boot.scr
   cd
   cleanup_on_exit
   rm -rf $CHROOT_SCRIPT

   sudo e2fsck -y -f $ROOTFS_TARGET_DISK
   sudo resize2fs -M $ROOTFS_TARGET_DISK
fi

echo "Rootfs Image: $ROOTFS_TARGET_DISK"
echo "Bootfs Image: $BOOTFS_TARGET_IMAGE"
