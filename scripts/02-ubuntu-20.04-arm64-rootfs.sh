#!/bin/bash

SCRIPTS_DIR="$(dirname $(realpath $0))"
[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="https://iweb.dl.sourceforge.net/project/arm-rootfs-ressources/ubuntu-base-20.04-base-arm64.tar.xz"

export BASE_ROOTFS_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export SHELL="/bin/bash"
export TERM="xterm-256color"
cd /
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
echo "APT::Install-Recommends "0";" >> /etc/apt/apt.conf.d/30norecommends
echo "APT::Install-Suggests "0";" >> /etc/apt/apt.conf.d/30norecommends
rm /etc/default/locale
touch /etc/default/locale
echo "LANGUAGE="en_US.UTF-8"" >> /etc/default/locale
echo "LC_ALL="en_US.UTF-8"" >> /etc/default/locale
echo "LC_PAPER="en_US.UTF-8"" >> /etc/default/locale
echo "LC_NUMERIC="en_US.UTF-8"" >> /etc/default/locale
echo "LC_IDENTIFICATION="en_US.UTF-8"" >> /etc/default/locale
echo "LC_MEASUREMENT="en_US.UTF-8"" >> /etc/default/locale
echo "LC_NAME="en_US.UTF-8"" >> /etc/default/locale
echo "LC_MESSAGES="POSIX"" >> /etc/default/locale
echo "LC_TELEPHONE="en_US.UTF-8"" >> /etc/default/locale
echo "LC_ADDRESS="en_US.UTF-8"" >> /etc/default/locale
echo "LC_MONETARY="en_US.UTF-8"" >> /etc/default/locale
echo "LC_TIME="en_US.UTF-8"" >> /etc/default/locale
echo "LANG="en_US.UTF-8"" >> /etc/default/locale
source /etc/default/locale
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true TZ="Europe/Stockholm"
apt-get -y clean
apt-get -y update
apt-get -y install --no-install-recommends apt-utils dialog locales
locale-gen "en_US.UTF-8"
update-locale LANGUAGE="en_US.UTF-8" LC_PAPER="en_US.UTF-8" \
   LC_NUMERIC="en_US.UTF-8" LC_IDENTIFICATION="en_US.UTF-8" LC_MEASUREMENT="en_US.UTF-8" \
   LC_NAME="en_US.UTF-8" LC_MESSAGES="POSIX" LC_TELEPHONE="en_US.UTF-8" LC_ADDRESS="en_US.UTF-8" \
   LC_MONETARY="en_US.UTF-8" LC_TIME="en_US.UTF-8" LANG="en_US.UTF-8"
ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
apt-get -y upgrade
apt-get -y install --no-install-recommends util-linux nano openssh-server systemd \
   udev systemd-sysv net-tools iproute2 iputils-ping ethtool isc-dhcp-client libyajl-dev \
   libfdt-dev libaio-dev libpixman-1-dev libglib2.0-dev libncurses-dev \
   libglib2.0-dev uuid-dev symlinks gcc g++ libsystemd-dev dbus-user-session tzdata
/14-cross-build-env.sh
echo "ubuntu-arm64" > /etc/hostname
echo "127.0.0.1    ubuntu-arm64    localhost" > /etc/hosts
hostname "ubuntu-arm64"
hostname
echo -e "root\nroot" | passwd root
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
cat /etc/ssh/sshd_config | \
   sed 's/\nPermitRootLogin .*/\n#PermitRootLogin/g' | \
   sed 's/\nPermitEmptyPasswords .*/\n#PermitEmptyPasswords/g' > /etc/ssh/sshd_config.tmp
cat /etc/ssh/sshd_config.tmp | \
   sed 's/PermitRootLogin .*no/\nPermitRootLogin yes/g' | \
   sed 's/PermitEmptyPasswords .*yes/\n#PermitEmptyPasswords no/g' > /etc/ssh/sshd_config
rm /etc/ssh/sshd_config.tmp
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
systemctl enable systemd-networkd
systemctl enable systemd-timesyncd.service
ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
echo "Europe/Stockholm" > /etc/timezone
export TZ="Europe/Stockholm"
dpkg-reconfigure --frontend noninteractive tzdata
unlink /etc/resolv.conf
ln -fs /run/systemd/resolve/resolv.conf /etc/resolv.conf
echo "tmpfs  /var/run  tmpfs  defaults,noatime,nosuid,nodev,noexec,mode=1777  0  0" > /etc/fstab
apt-get -y clean
rm -rf /var/cache/*
rm -rf /var/log/*
rm -rf /var/lib/apt/lists/*
rm -rf /usr/share/doc/* /usr/share/X11/* /usr/share/man/*
rm -rf /lib/firmware/*
rm -rf /boot/*
df -h .
EOF
)

## timedatectl set-ntp true
## date --set="23 June 1988 10:00:00"; hwclock --systohc

export BASE_ROOTFS_POST_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
[ ! -d \$1 ] &&  echo "Invalid arg1: no such file or directory" && exit 1
echo "Run BASE_ROOTFS_POST_CHROOT_SCRIPT at \$1"
rm -rf \$1/root/*
cp $SCRIPTS_DIR/files/bashrc  \$1/root/.bashrc
cp $SCRIPTS_DIR/files/profile  \$1/root/.profile
cp $SCRIPTS_DIR/files/timesyncd.conf  \$1/etc/systemd/timesyncd.conf
cp $SCRIPTS_DIR/files/01-eth0-dhcp.network  \$1/etc/systemd/network/01-eth0-dhcp.network
cp $SCRIPTS_DIR/files/interfaces  \$1/etc/network/interfaces
EOF
)

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh
