#!/bin/bash
SCRIPTS_DIR="$(dirname $(realpath $0))"
[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="https://iweb.dl.sourceforge.net/project/arm-rootfs-ressources/centos-7-2003-aarch64-rootfs.tar.xz"

export BASE_ROOTFS_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
cd /
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
yum -y update --exclude=*raspberrypi*  --exclude=*kernel* --exclude=redhat-release* --exclude=centos-release*
#rpm -qa --queryformat 'yum -y remove %-25{name} \n' > /cleanup.sh
yum -y remove grub2-common NetworkManager-wifi uboot-images-armv8 postfix chrony basesystem parted dracut-config-extradrivers sg3_utils man-db \
   shim-aa64 efibootmgr grubby grub2-efi-aa64-modules rootfiles iwl6050-firmware iwl6000g2a-firmware iwl5150-firmware iwl4965-firmware iwl3160-firmware \
   iwl2000-firmware iwl105-firmware iwl100-firmware systemd-sysv libnl3 file libunistring e2fsprogs-libs ethtool python-decorator jansson python-slip \
   python-configobj python-linux-procfs python-schedutils gettext-libs less libteam ipset python-gobject-base fipscheck mariadb-libs logrotate mozjs17 \
   libss freetype dtc libestr libndp libseccomp lsscsi pciutils-libs sg3_utils-libs newt polkit-pkla-compat iputils grub2-tools-minimal cronie-anacron \
   crontabs grub2-tools NetworkManager-libnm policycoreutils dracut-network grub2-efi-aa64 fxload alsa-tools-firmware libdrm dbus-python python-firewall \
   plymouth-core-libs plymouth virt-what linux-firmware kernel-modules kbd-legacy firewalld kernel tuned lshw kexec-tools NetworkManager-tui \
   uboot-images-armv7 audit aic94xx-firmware irqbalance rsyslog cloud-utils-growpart iprutils e2fsprogs btrfs-progs xfsprogs libsysfs bcm283x-firmware iwl7260-firmware \
   iwl6000g2b-firmware iwl6000-firmware iwl5000-firmware iwl3945-firmware iwl2030-firmware iwl135-firmware iwl1000-firmware ivtv-firmware which libcroco libnl3-cli groff-base \
   libedit efivar-libs lzo tcp_wrappers-libs libselinux-python python-perf mokutil gettext ipset-libs gobject-introspection fipscheck-lib alsa-lib centos-logos libselinux-utils \
   vim-minimal snappy libpng dmidecode libdaemon libfastjson libpipeline numactl-libs slang polkit wpa_supplicant cronie os-prober uboot-tools NetworkManager openssh selinux-policy \
   grub2-tools-extra ebtables alsa-firmware hwdata dbus-glib python-slip-dbus teamd plymouth-scripts python-pyudev kernel-tools-libs kernel-core kbd-misc firewalld-filesystem kbd \
   kernel-tools NetworkManager-team grub2 selinux-policy-targeted libnfnetlink sysvinit-tools raspberrypi2-kernel raspberrypi2-kernel-devel raspberrypi2-kernel4 \
   raspberrypi2-firmware raspberrypi-vc-libs-devel raspberrypi2-kernel4
yum install -y dhclient iputils nano net-tools yajl-devel libfdt-devel libaio-devel pixman-devel libgcc glibc-devel gcc gcc-c++ openssh-server openssh-clients ntp ntpdate \
   glib2-devel libstdc++-devel ncurses-devel uuid-devel systemd-devel symlinks zlib-devel libuuid-devel
yum clean all
/14-cross-build-env.sh
echo "centos7-arm64" > /etc/hostname
echo "127.0.0.1    centos7-arm64    localhost" > /etc/hosts
hostname "centos7-arm64"
hostname
echo "" > /etc/fstab
echo -e "root\nroot" | passwd root
systemctl enable ntpd.service
systemctl enable ntpdate.service
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default
cat /etc/ssh/sshd_config | \
   sed 's/\nPermitRootLogin .*/\n#PermitRootLogin/g' | \
   sed 's/\nPermitEmptyPasswords .*/\n#PermitEmptyPasswords/g' > /etc/ssh/sshd_config.tmp
cat /etc/ssh/sshd_config.tmp | \
   sed 's/PermitRootLogin .*no/\nPermitRootLogin yes/g' | \
   sed 's/PermitEmptyPasswords .*yes/\n#PermitEmptyPasswords no/g' > /etc/ssh/sshd_config
rm /etc/ssh/sshd_config.tmp
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
unlink /etc/resolv.conf
ln -fs /run/resolv.conf /etc/resolv.conf
ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
rm -rf /var/lib/yum/yumdb/*
rm -rf /var/cache/yum/*
rm -rf /usr/share/doc/* /usr/share/X11/* /usr/share/man/* /usr/local/share/man/*
mv /usr/share/locale/en_US /usr/share/locale/locale.alias /
rm -rf /usr/share/locale/*
mv /locale.alias /en_US /usr/share/locale/
rm -rf /lib/firmware/*
rm -rf /boot/*
df -h .
EOF
)

# localedef --list-archive | grep -v -i ^en_US | xargs localedef --delete-from-archive
# build-locale-archive
# mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
# build-locale-archive
# rm /usr/lib/locale/locale-archive.tmpl

export BASE_ROOTFS_POST_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
[ ! -d \$1 ] &&  echo "Invalid arg1: no such file or directory" && exit 1
echo "Run BASE_ROOTFS_POST_CHROOT_SCRIPT at \$1"
rm -rf \$1/root/*
cp $SCRIPTS_DIR/files/bashrc  \$1/root/.bashrc
cp $SCRIPTS_DIR/files/profile  \$1/root/.profile
cp $SCRIPTS_DIR/files/timesyncd.conf  \$1/etc/systemd/timesyncd.conf
cp $SCRIPTS_DIR/files/ntpdate  \$1/etc/sysconfig/ntpdate
cp $SCRIPTS_DIR/files/ifcfg-eth0-dhcp  \$1/etc/sysconfig/network-scripts/ifcfg-eth0
patch --verbose \$1/etc/sysconfig/network-scripts/ifup-eth $SCRIPTS_DIR/files/centos-7-ifup-eth.patch
rm \$1/usr/lib/locale/locale-archive
cp $SCRIPTS_DIR/files/centos-7-locale-archive \$1/usr/lib/locale/locale-archive
df -h \$1/
EOF
)

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh
