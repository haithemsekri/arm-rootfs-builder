#!/bin/bash
SCRIPTS_DIR="$(dirname $(realpath $0))"
[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="https://iweb.dl.sourceforge.net/project/arm-rootfs-ressources/centos-7-2003-armv7hl-rootfs.tar.xz"

export BASE_ROOTFS_PRE_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
[ ! -d \$1 ] &&  echo "Invalid arg1: no such file or directory" && exit 1
echo "BASE_ROOTFS_PRE_CHROOT_SCRIPT: \$1"
umount \$1/proc
cp $SCRIPTS_DIR/01-centos-7-arm32-cpuinfo \$1/proc/cpuinfo
EOF
)

export BASE_ROOTFS_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
cd /
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
echo "centos7-arm32" > /etc/hostname
echo "127.0.0.1    centos7-arm32    localhost" > /etc/hosts
hostname "centos7-arm32 "
hostname
passwd

yum -y update --exclude=*raspberrypi*  --exclude=*kernel* --exclude=redhat-release* --exclude=centos-release*

yum -y remove openssh-server grub2-common NetworkManager-wifi uboot-images-armv8 postfix chrony basesystem parted dracut-config-extradrivers sg3_utils man-db \
   shim-aa64 efibootmgr grubby grub2-efi-aa64-modules rootfiles iwl6050-firmware iwl6000g2a-firmware iwl5150-firmware iwl4965-firmware iwl3160-firmware \
   iwl2000-firmware iwl105-firmware iwl100-firmware systemd-sysv libnl3 file libunistring e2fsprogs-libs ethtool python-decorator jansson python-slip \
   python-configobj python-linux-procfs python-schedutils gettext-libs less libteam ipset python-gobject-base fipscheck mariadb-libs logrotate acl mozjs17 \
   libss freetype dtc libestr libndp libseccomp lsscsi pciutils-libs sg3_utils-libs newt polkit-pkla-compat iputils grub2-tools-minimal cronie-anacron \
   crontabs grub2-tools NetworkManager-libnm policycoreutils dracut-network grub2-efi-aa64 fxload alsa-tools-firmware libdrm dbus-python python-firewall \
   plymouth-core-libs plymouth virt-what linux-firmware kernel-modules kbd-legacy firewalld kernel tuned lshw kexec-tools openssh-clients NetworkManager-tui \
   uboot-images-armv7 audit aic94xx-firmware irqbalance rsyslog cloud-utils-growpart iprutils e2fsprogs btrfs-progs xfsprogs libsysfs bcm283x-firmware iwl7260-firmware \
   iwl6000g2b-firmware iwl6000-firmware iwl5000-firmware iwl3945-firmware iwl2030-firmware iwl135-firmware iwl1000-firmware ivtv-firmware which libcroco libnl3-cli groff-base \
   libedit efivar-libs lzo tcp_wrappers-libs libselinux-python python-perf mokutil gettext ipset-libs gobject-introspection fipscheck-lib alsa-lib centos-logos libselinux-utils \
   vim-minimal snappy libpng dmidecode libdaemon libfastjson libpipeline numactl-libs slang polkit wpa_supplicant cronie os-prober uboot-tools NetworkManager openssh selinux-policy \
   grub2-tools-extra ebtables alsa-firmware hwdata dbus-glib python-slip-dbus teamd plymouth-scripts python-pyudev kernel-tools-libs kernel-core kbd-misc firewalld-filesystem kbd \
   kernel-tools NetworkManager-team grub2 selinux-policy-targeted passwd acl net-tools extlinux-bootloader \
   raspberrypi2-kernel raspberrypi2-kernel-devel raspberrypi2-kernel4 raspberrypi2-firmware raspberrypi-vc-libs-devel  raspberrypi2-kernel4

yum install -y dhclient iputils nano net-tools yajl-devel libfdt-devel libaio-devel pixman-devel libgcc glibc-devel gcc gcc-c++ \
   glib2-devel libstdc++-devel ncurses-devel uuid-devel systemd-devel symlinks zlib-devel libuuid-devel

/14-cross-build-env.sh

find / -type l -name "*.so" | xargs dirname | xargs symlinks -c
find / \( -name "ld-linux*.so*" -o  -name "libstdc++.so" -o  -name "libpthread.so" -o  -name "libc.so" -o  -name "libcrypt.so" \) | xargs dirname | xargs symlinks -c

echo "" > /etc/fstab
rm /proc/cpuinfo
rm -rf /lib/firmware/*
rm -rf /root/*
df -h .
EOF
)

export TARGET_ROOTFS_PRE_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
[ ! -d \$1 ] &&  echo "Invalid arg1: no such file or directory" && exit 1
echo "BASE_ROOTFS_PRE_CHROOT_SCRIPT: \$1"
sync
umount \$1/proc
umount -f -l \$1/proc
cp $SCRIPTS_DIR/01-centos-7-arm32-cpuinfo \$1/proc/cpuinfo
EOF
)

export TARGET_ROOTFS_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
printenv
yum -y remove gcc gcc-c++ systemd-devel
yum clean all
find / -type f -name "lib*.a" | xargs rm -rf
find / -type f -name "*.h" | xargs rm -rf
mv /usr/share/locale/en_US /
mv /usr/share/locale/uk /
rm -rf /usr/share/doc/*
rm -rf /usr/share/locale/*
rm -rf /usr/lib/*.a
rm -rf /usr/lib/gcc/*/*/*.a
mv /en_US /uk /usr/share/locale/
rm /usr/lib/locale/locale-archive
rm -rf /var/lib/yum/yumdb/*
rm -rf /var/cache/yum/*
rm -rf /usr/local/share/man/*
rm -rf /include/* /usr/include/* /usr/share/doc/* /usr/share/X11/* /usr/share/man/*
df -h .
EOF
)

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh
