#!/bin/bash

SCRIPTS_DIR="$(dirname $(realpath $0))"
[ -z $ROOTFS_DL_URL ]  && ROOTFS_DL_URL="https://iweb.dl.sourceforge.net/project/arm-rootfs-ressources/ubuntu-base-14.04.6-base-arm64.tar.xz"

export BASE_ROOTFS_PRE_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
[ ! -d \$1 ] &&  echo "Invalid arg1: no such file or directory" && exit 1
rm -rf  \$1/root/*
cp $SCRIPTS_DIR/files/bashrc  \$1/root/.bashrc.orig
cp $SCRIPTS_DIR/files/profile  \$1/root/.bash_profile.orig
cp $SCRIPTS_DIR/files/bashrc  \$1/root/.bashrc
cp $SCRIPTS_DIR/files/profile  \$1/root/.bash_profile
cp $SCRIPTS_DIR/files/ttyhvc0.conf  \$1/etc/init/ttyhvc0.conf
EOF
)

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
echo "ubuntu-arm64" > /etc/hostname
echo "127.0.0.1    ubuntu-arm64    localhost" > /etc/hosts
hostname "ubuntu-arm64"
hostname
echo "tmpfs  /var/run  tmpfs  defaults,noatime,nosuid,nodev,noexec,mode=1777  0  0" > /etc/fstab
passwd

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
apt-get -y install --no-install-recommends util-linux nano openssh-server udev net-tools iproute2 \
   iputils-ping ethtool isc-dhcp-client realpath libyajl-dev libfdt-dev libaio-dev libpixman-1-dev \
   libglib2.0-dev libgcc-4.8-dev libstdc++-4.8-dev libncurses-dev uuid-dev gcc g++ symlinks

/14-cross-build-env.sh

find / -type l -name "*.so" | xargs dirname | xargs symlinks -c
find / \( -name "ld-linux*.so*" -o  -name "libstdc++.so" -o  -name "libpthread.so" -o  -name "libc.so" -o  -name "libcrypt.so" \) | xargs dirname | xargs symlinks -c

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
cat /etc/ssh/sshd_config | \
   sed 's/PermitRootLogin /#PermitRootLogin /g' | \
   sed 's/PermitEmptyPasswords /#PermitEmptyPasswords /g'  > /etc/ssh/sshd_config.tmp
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

cp /root/.bashrc.orig /root/.bashrc
cp /root/.profile.orig /root/.bash_profile
rm -rf /lib/firmware/*
apt-get -y clean
df -h .
EOF
)

export TARGET_ROOTFS_CHROOT_SCRIPT=$(cat << EOF
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export SHELL="/bin/bash"
export TERM="xterm-256color"
source /etc/default/locale
apt-get -y remove binutils cpp cpp-4.8 g++ g++-4.8 gcc gcc-4.8 libcloog-isl4 libgmp10 libisl10 libmpc3 libmpfr4 symlinks
apt-get -y autoremove
apt-get clean
rm -rf /var/cache/*
rm -rf /var/log/*
rm -rf /var/lib/apt/lists/*
find / -type f -name "lib*.a" | xargs rm -rf
find / -type f -name "*.h" | xargs rm -rf
rm -rf /include/* /usr/include/* /usr/share/doc/* /usr/share/X11/* /usr/share/man/*
cp /root/.bashrc.orig /root/.bashrc
cp /root/.profile.orig /root/.bash_profile
df -h .
EOF
)

source $(dirname $(realpath $0))/00-distro-rootfs-common.sh
