#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="http://ftp.rz.uni-frankfurt.de/pub/mirrors/centos-altarch/7.8.2003/isos/aarch64/images/CentOS-Userland-7-aarch64-RaspberryPI-Minimal-4-2003-sda.raw.xz"
[ -z $ROOTFS_DL_TAR ] && ROOTFS_DL_TAR="$DL_DIR/$(basename $ROOTFS_DL_URL)"

[ ! -f $ROOTFS_DL_TAR ] && wget $ROOTFS_DL_URL -O $ROOTFS_DL_TAR
[ ! -f $ROOTFS_DL_TAR ] && echo "$ROOTFS_DL_TAR : file not found" && exit 1

build_base_rootfs_disk() {
if [ -f $ROOTFS_BASE_TAR ]; then
   echo "Based on: $ROOTFS_BASE_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_BASE_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB
else
   echo "Based on: $ROOTFS_DL_TAR"
   TMP_DIR=$BUILD_DIR/tar.xz.tmp
   rm -rf $TMP_DIR
   mkdir -p $TMP_DIR

   [ ! -f $TMP_DIR/disk.raw ] && unxz -k -c $ROOTFS_DL_TAR > $TMP_DIR/disk.raw
   [ ! -f $TMP_DIR/disk.raw ] && echo "$TMP_DIR/disk.raw : file not found" && exit 1

   PART="$(kpartx -avs $TMP_DIR/disk.raw | awk '{print $3}')"
   echo "PART: $PART"
   LOOP_DEV="$(echo $PART | awk '{print $3}')"
   [ -z $LOOP_DEV ] && kpartx -dvs $TMP_DIR/disk.raw && rm -rf $TMP_DIR && "LOOP_DEV: device not found" && exit 1
   LOOP_DEV="/dev/mapper/$LOOP_DEV"
   echo "LOOP_DEV: $LOOP_DEV"
   [ ! -b $LOOP_DEV ] && kpartx -dvs $TMP_DIR/disk.raw && rm -rf $TMP_DIR  && "$LOOP_DEV: device not found" && exit 1

   dd if=$LOOP_DEV of=$ROOTFS_BASE_DISK status=progress
   sync
   kpartx -dvs $TMP_DIR/disk.raw
   rm -rf $TMP_DIR

   echo "ROOTFS_BASE_DISK: $ROOTFS_BASE_DISK"
   [ ! -f $ROOTFS_BASE_DISK ] && echo "$ROOTFS_BASE_DISK : file not found" && exit 1

   CHROOT_SCRIPT="$BUILD_DIR/chroot-script.sh"
   rm -rf  $CHROOT_SCRIPT

cat <<EOF > $CHROOT_SCRIPT
#!/bin/bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf

passwd

yum -y update --exclude=*raspberrypi*  --exclude=*kernel* --exclude=redhat-release* --exclude=centos-release*

#rpm -qa --queryformat 'yum -y remove %-25{name} \n' > /cleanup.sh
yum -y remove openssh-server grub2-common NetworkManager-wifi uboot-images-armv8 postfix chrony basesystem parted dracut-config-extradrivers sg3_utils man-db \
   shim-aa64 efibootmgr grubby grub2-efi-aa64-modules rootfiles iwl6050-firmware iwl6000g2a-firmware iwl5150-firmware iwl4965-firmware iwl3160-firmware \
   iwl2000-firmware iwl105-firmware iwl100-firmware systemd-sysv libnl3 file libunistring e2fsprogs-libs ethtool python-decorator jansson python-slip \
   python-configobj python-linux-procfs python-schedutils gettext-libs less libteam ipset python-gobject-base fipscheck mariadb-libs logrotate mozjs17 \
   libss freetype dtc libestr libndp libseccomp lsscsi pciutils-libs sg3_utils-libs newt polkit-pkla-compat iputils grub2-tools-minimal cronie-anacron \
   crontabs grub2-tools NetworkManager-libnm policycoreutils dracut-network grub2-efi-aa64 fxload alsa-tools-firmware libdrm dbus-python python-firewall \
   plymouth-core-libs plymouth virt-what linux-firmware kernel-modules kbd-legacy firewalld kernel tuned lshw kexec-tools openssh-clients NetworkManager-tui \
   uboot-images-armv7 audit aic94xx-firmware irqbalance rsyslog cloud-utils-growpart iprutils e2fsprogs btrfs-progs xfsprogs libsysfs bcm283x-firmware iwl7260-firmware \
   iwl6000g2b-firmware iwl6000-firmware iwl5000-firmware iwl3945-firmware iwl2030-firmware iwl135-firmware iwl1000-firmware ivtv-firmware which libcroco libnl3-cli groff-base \
   libedit efivar-libs lzo tcp_wrappers-libs libselinux-python python-perf mokutil gettext ipset-libs gobject-introspection fipscheck-lib alsa-lib centos-logos libselinux-utils \
   vim-minimal snappy libpng dmidecode libdaemon libfastjson libpipeline numactl-libs slang polkit wpa_supplicant cronie os-prober uboot-tools NetworkManager openssh selinux-policy \
   grub2-tools-extra ebtables alsa-firmware hwdata dbus-glib python-slip-dbus teamd plymouth-scripts python-pyudev kernel-tools-libs kernel-core kbd-misc firewalld-filesystem kbd \
   kernel-tools NetworkManager-team grub2 selinux-policy-targeted libnfnetlink sysvinit-tools raspberrypi2-kernel raspberrypi2-kernel-devel raspberrypi2-kernel4 \
   raspberrypi2-firmware raspberrypi-vc-libs-devel  raspberrypi2-kernel4

yum install -y dhclient iputils nano net-tools yajl-devel libfdt-devel libaio-devel pixman-devel libgcc glibc-devel gcc gcc-c++ \
   glib2-devel libstdc++-devel ncurses-devel uuid-devel systemd-devel symlinks zlib-devel libuuid-devel

echo "Run symlinks"
symlinks -c /usr/lib/gcc/aarch64-redhat-linux/
symlinks -c /usr/lib/gcc/aarch64-redhat-linux/*/
echo "" > /etc/fstab
yum clean all

EOF

   export ROOTFS_DISK_PATH=$ROOTFS_BASE_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   chroot_run_script $CHROOT_SCRIPT
   sync
   rm -rf $CHROOT_SCRIPT
   chroot_umount_pseudo_fs
   cd $RTFS_MNT_DIR
   tar -czf $ROOTFS_BASE_TAR .
   cd -
   cleanup_on_exit
   rm -rf $ROOTFS_BASE_DISK
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_BASE_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB

   #rsync -avlz  $SCRIPTS_DIR/overlays/  ${RTFS_MNT_DIR}/
fi
}

build_target_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   cp $ROOTFS_BASE_DISK $ROOTFS_TARGET_DISK
   CHROOT_SCRIPT="$BUILD_DIR/chroot-script.sh"
   rm -rf  $CHROOT_SCRIPT

cat <<EOF > $CHROOT_SCRIPT
#!/bin/bash
echo "Cleaning everything"
yum -y remove gcc gcc-c++ systemd-devel
yum clean all
mv /usr/share/locale/en_US /
mv /usr/share/locale/uk /
rm /usr/lib/locale/*
rm -rf /usr/share/doc/*
rm -rf /usr/share/locale/*
rm -rf /usr/lib/*.a
rm -rf /usr/lib/gcc/*/*/*.a
mv /en_US /uk /usr/share/locale/
localedef --list-archive | grep -v -i ^en | xargs localedef --delete-from-archive
EOF
   export ROOTFS_DISK_PATH=$ROOTFS_TARGET_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   chroot_run_script $CHROOT_SCRIPT
   sync
   rm -rf $CHROOT_SCRIPT
   cleanup_on_exit
}

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh

