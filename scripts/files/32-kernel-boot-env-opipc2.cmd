
#mkimage -C none -A arm -T script -d boot.cmd boot.scr

echo "======================================================================="
echo "load_cmd: $load_cmd"
echo "rootfs_path: $rootfs_path"
echo "dtb_addr_r: $dtb_addr_r"
echo "kernel_addr_r: $kernel_addr_r"
echo "======================================================================="

## setenv dtb_addr_r 0x4FA00000
## setenv kernel_addr_r 0x40080000
## setenv rootfs_path /dev/mmcblk0p2
## setenv load_cmd ext4load mmc 0:2

setenv dtb_path boot/dtb
$load_cmd $dtb_addr_r $dtb_path

setenv kernel_path boot/kernel
$load_cmd $kernel_addr_r $kernel_path

setenv bootargs "root=$rootfs_path rootwait rw console=ttyS0,115200 panic=10 consoleblank=0 loglevel=7 ip=dhcp"

booti $kernel_addr_r - $dtb_addr_r
