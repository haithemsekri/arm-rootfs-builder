#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.4-base-armhf.tar.gz"
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
apt-get -y install --no-install-recommends util-linux nano openssh-server systemd \
	udev systemd-sysv net-tools iproute2 iputils-ping ethtool isc-dhcp-client

######################################Runtime libs######################################
apt-get -y install --no-install-recommends libyajl-dev \
   libfdt-dev libaio-dev libpixman-1-dev libglib2.0-dev

######################################Dev libs##########################################
apt-get -y install --no-install-recommends libgcc-7-dev libstdc++-7-dev libncurses-dev \
   libsystemd-dev symlinks  uuid-dev

symlinks -c /usr/lib/arm-linux-gnueabihf/
symlinks -c /usr/lib/arm-linux-gnueabihf/*/
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

#binutils binutils-arm-linux-gnueabihf binutils-common dpkg-dev libaio-dev libaio1 libbinutils libc-dev-bin libc6-dev libdpkg-perl libexpat1 libfdt-dev libfdt1 libgdbm-compat4 libgdbm5 libglib2.0-0
#libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libmpdec2 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libperl5.26 libpixman-1-0 libpixman-1-dev libyajl-dev libyajl2 linux-libc-dev

apt-get -y remove libpython3-stdlib libpython3.6-minimal libpython3.6-stdlib libreadline7 libsqlite3-0 \
   make mime-support patch perl perl-modules-5.26 pkg-config python3 python3-distutils \
   python3-lib2to3 python3-minimal python3.6 python3.6-minimal readline-common xz-utils zlib1g-dev \
   cpp cpp-7 g++ g++-7 gcc gcc-7 gcc-7-base libasan4 libatomic1 libcc1-0 libcilkrts5 libgcc-7-dev libgomp1 \
   libisl19 libmpc3 libmpfr6 libncurses5-dev libstdc++-7-dev libsystemd-dev libtinfo-dev libubsan0 symlinks

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

