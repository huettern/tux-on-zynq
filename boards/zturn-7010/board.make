
UBOOT_DEFCONFIG		= uboot/myir-zturn-7010_defconfig
UBOOT_DTS 			= uboot/zturn_7010.dts
UBOOT_SCR_SRC 		= uboot/boot.txt
UBOOT_UENV_SRC 		= uboot/uEnv.txt

LINUX_DEFCONFIG		= linux/myir-zturn-7010_defconfig

# user supplied device tree
DTREE_USER_SRC		= dtree/myir-zturn-7010.dts
DTREE_BOOT_ARGS 	= "console=ttyPS0,115200 earlyprintk"

# Select which initramfs should be created
# - buildroot
# - busybox
INIT_CHOICE			= buildroot

# buildroot
BUILDROOT_DEFCONFIG	= buildroot/myir-zturn-7010_defconfig

# busybox
BUSYBOX_DEFCONFIG	= busybox/myir-zturn-7010_config
BUSYBOX_RCS 		= busybox/rcS