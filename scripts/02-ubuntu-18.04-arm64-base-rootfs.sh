#!/bin/bash

source $(dirname $(realpath $0))/00-distro-rootfs-env.sh

[ -z $ROOTFS_DL_FILE ] && ROOTFS_DL_FILE="$DL_DIR/$DISTRO_NAME-base.raw.xz"
[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.1-base-arm64.tar.gz"

[ ! -f $ROOTFS_DL_FILE ] && wget $ROOTFS_DL_URL -O $ROOTFS_DL_FILE
[ ! -f $ROOTFS_DL_FILE ] && echo "$ROOTFS_DL_FILE : file not found"

DISK_SIZE_MB=1024

create_rootfs_disk() {
if [ -f $ROOTFS_BASE_TAR ]; then
   echo "Based on: $ROOTFS_BASE_TAR"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_BASE_TAR $ROOTFS_BASE_DISK $DISK_SIZE_MB
else
   echo "Based on: $ROOTFS_DL_FILE"
   $SCRIPTS_DIR/10-tar-to-disk-image.sh $ROOTFS_DL_FILE $ROOTFS_BASE_DISK $DISK_SIZE_MB
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
apt-get -y install --no-install-recommends util-linux nano openssh-server
apt-get -y install --no-install-recommends systemd udev systemd-sysv
apt-get -y install --no-install-recommends net-tools iproute2 iputils-ping ethtool isc-dhcp-client

######################################Runtime libs######################################
apt-get -q -y install --no-install-recommends libyajl-dev \
   libfdt-dev libaio-dev libpixman-1-dev libglib2.0-dev

######################################Dev libs##########################################
apt-get -y install --no-install-recommends libgcc-7-dev libstdc++-7-dev libncurses-dev libglib2.0-dev libsystemd-dev gcc g++
apt-get -y install --no-install-recommends symlinks
symlinks -c /usr/lib/aarch64-linux-gnu
EOF

   export ROOTFS_DISK_PATH=$ROOTFS_BASE_DISK
   source $SCRIPTS_DIR/12-chroot-run.sh
   chroot_run_script $CHROOT_SCRIPT
   rm -rf $CHROOT_SCRIPT
   sudo rsync -avlz  $SCRIPTS_DIR/overlays/  ${RTFS_MNT_DIR}/
   cleanup_on_exit
fi
}

backup_rootfs_disk() {
   echo "Based on: $ROOTFS_BASE_DISK"
   $SCRIPTS_DIR/11-disk-image-to-tar.sh $ROOTFS_BASE_DISK $ROOTFS_BASE_TAR
}

if [ "$1" == "--rebuild" ]; then
   echo -n ""
fi

if [ "$1" == "--clean-rebuild" ]; then
   echo "delete $ROOTFS_BASE_DISK"
   rm -rf "$ROOTFS_BASE_DISK"
   echo "delete $ROOTFS_BASE_TAR"
   rm -rf "$ROOTFS_BASE_TAR"
fi

echo "Building $ROOTFS_BASE_DISK"
[ ! -f $ROOTFS_BASE_DISK ] && create_rootfs_disk
echo "Building $ROOTFS_BASE_TAR"
[ ! -f $ROOTFS_BASE_TAR ] && backup_rootfs_disk

sudo chmod 666 $ROOTFS_BASE_DISK
sudo chmod 666 $ROOTFS_BASE_TAR