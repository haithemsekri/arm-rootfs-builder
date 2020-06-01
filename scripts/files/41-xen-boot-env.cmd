
#mkimage -C none -A arm -T script -d boot.cmd boot.scr

echo "======================================================================="
echo "load_cmd: $load_cmd"
echo "rootfs_path: $rootfs_path"
echo "kernel_addr_r: $kernel_addr_r"
echo "xen_addr_r: $xen_addr_r"
echo "dtb_addr_r: $dtb_addr_r"
echo "======================================================================="

## setenv kernel_addr_r 0x50000000
## setenv xen_addr_r 0x46000000
## setenv dtb_addr_r 0x45000000
## setenv load_cmd "ext4load usb 0:1"

setenv kernel_path boot/kernel
setenv xen_path boot/xen
setenv dtb_path boot/dtb

$load_cmd $kernel_addr_r $kernel_path
setenv kernel_size 0x$filesize
$load_cmd $xen_addr_r $xen_path
$load_cmd $dtb_addr_r $dtb_path

fdt addr $dtb_addr_r
fdt resize

fdt mknode /chosen modules
fdt set /chosen/modules '#address-cells' <1>
fdt set /chosen/modules '#size-cells' <1>

fdt mknode /chosen/modules module@0
fdt set /chosen/modules/module@0 compatible xen,linux-zimage xen,multiboot-module
fdt set /chosen/modules/module@0 reg <$kernel_addr_r $kernel_size>
fdt set /chosen xen,xen-bootargs "console=dtuart dtuart=serial0 dom0_mem=256M"
fdt set /chosen xen,dom0-bootargs "root=$rootfs_path rootwait rw console=hvc0 earlyprintk=xen panic=10 consoleblank=0 loglevel=7 ip=dhcp clk_ignore_unused"

fdt print /chosen
booti $xen_addr_r - $dtb_addr_r

