#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/14.04/release/ubuntu-base-14.04.6-base-arm64.tar.gz"
[ -z $ROOTFS_DL_TAR ] && ROOTFS_DL_TAR="$DL_DIR/$(basename $ROOTFS_DL_URL)"

[ ! -f $ROOTFS_DL_TAR ] && wget $ROOTFS_DL_URL -O $ROOTFS_DL_TAR
[ ! -f $ROOTFS_DL_TAR ] && echo "$ROOTFS_DL_TAR : file not found" && exit 1

build_base_rootfs_disk() {
if [ -f $ROOTFS_BASE_TAR ]; then
   echo "Based on: $ROOTFS_BASE_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_BASE_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB
else
   echo "Based on: $ROOTFS_DL_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_DL_TAR $ROOTFS_BASE_DISK $DISTRO_SIZE_MB
   CHROOT_SCRIPT="$BUILD_DIR/chroot-script.sh"
   rm -rf  $CHROOT_SCRIPT

cat <<EOF > $CHROOT_SCRIPT
#!/bin/bash
######################################Basic distro######################################
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
echo "LANG=en_US.UTF-8" > /etc/default/locale
echo "APT::Install-Recommends "0";" >> /etc/apt/apt.conf.d/30norecommends
echo "APT::Install-Suggests "0";" >> /etc/apt/apt.conf.d/30norecommends

passwd

apt-get -y clean
apt-get -y update
apt-get -y install --no-install-recommends apt-utils dialog
apt-get -y install --no-install-recommends locales
locale-gen en_US.UTF-8

apt-get -y upgrade
apt-get -y install --no-install-recommends util-linux nano openssh-server udev \
	net-tools iproute2 iputils-ping ethtool isc-dhcp-client

######################################Runtime libs######################################
apt-get -y install --no-install-recommends libyajl-dev \
   libfdt-dev libaio-dev libpixman-1-dev libglib2.0-dev

######################################Dev libs##########################################
apt-get -y install --no-install-recommends libncurses-dev gcc g++ symlinks

symlinks -c /usr/lib/gcc/aarch64-linux-gnu/
symlinks -c /usr/lib/gcc/aarch64-linux-gnu/*/
echo "" > /etc/fstab
apt-get -y clean
rm -rf /var/cache/apt/*

EOF

   export ROOTFS_DISK_PATH=$ROOTFS_BASE_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   chroot_run_script $CHROOT_SCRIPT
   rm -rf $CHROOT_SCRIPT
   rsync -avlz  $SCRIPTS_DIR/overlays/  ${RTFS_MNT_DIR}/
   cleanup_on_exit
fi
}

build_target_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   cp $ROOTFS_BASE_DISK $ROOTFS_TARGET_DISK
   CHROOT_SCRIPT="$BUILD_DIR/chroot-script.sh"
   rm -rf  $CHROOT_SCRIPT

cat <<EOF > $CHROOT_SCRIPT
#!/bin/bash

apt-get -y remove libpython2.7-minimal libpython2.7-stdlib libpython-stdlib pkg-config python python-minimal python2.7 python2.7-minimal \
   binutils cpp cpp-4.8 g++ g++-4.8 gcc gcc-4.8 libatomic1 libcloog-isl4 \
   libgcc-4.8-dev libgmp10 libgomp1 libisl10 libitm1 libmpc3 libmpfr4 \
   libncurses5-dev libstdc++-4.8-dev libtinfo-dev symlinks \

#libaio-dev libaio1 libc-dev-bin libc6-dev libelfg0 libfdt-dev libfdt1
#libglib2.0-0 libglib2.0-bin libglib2.0-data libglib2.0-dev libpcre3-dev
#libpcrecpp0 libpixman-1-0 libpixman-1-dev libyajl-dev libyajl2 linux-libc-dev zlib1g-dev

apt-get -y clean

rm -rf /var/cache/apt
#rm -rf /var/lib/apt
rm -rf /var/log/apt
#rm /usr/lib/apt/apt.systemd.daily
#rm -rf /usr/include/*
#rm -rf /include
#rm -rf /usr/locale
rm -rf /lib/*.a
rm -rf /usr/lib/aarch64-linux-gnu/*.a
#rm -rf /usr/share/*
#rm -rf /share/*
#rm -rf /usr/lib/aarch64-linux-gnu/perl-base
EOF
   export ROOTFS_DISK_PATH=$ROOTFS_TARGET_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   chroot_run_script $CHROOT_SCRIPT
   sync
   rm -rf $CHROOT_SCRIPT
   cleanup_on_exit
}

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh

