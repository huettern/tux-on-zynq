
################################################################################
# Project settings

# Project name
NAME	= zturn

# Board name for all board specific fils in the boards folder
BOARD 	= zturn-7010
include boards/$(BOARD)/board.make

# Path to the vivado project
XPR		= $$HOME/git/zynq-sandbox/fpga/hlx/build/projects/zturn-lcd-vdma.xpr

# Path to the hlx bitstream if exists
# BIT		= 
BIT		= $$HOME/git/zynq-sandbox/fpga/hlx/build/projects/zturn-lcd-vdma.runs/impl_1/system_wrapper.bit

# Processor to use for FSBL
PROC 	= ps7_cortexa9_0

# uboot version
# Choos from the releases on https://github.com/Xilinx/u-boot-xlnx/releases
UBOOT_TAG 	= xilinx-v2020.1

# Linux kernel version, Major version for correct url on cdn.kernel.org
LINUX_MAJOR	= v5.x
LINUX_TAG	= 5.4.61

# device tree utilities, fetched from https://github.com/Xilinx/device-tree-xlnx/archive/$(DTREE_TAG).tar.gz
DTREE_TAG	= xilinx-v2020.1

# If using buildroot, specify version here
BUILDROOT_TAG	= 2020.08

# If using busybox, specify version here
BUSYBOX_TAG		= 1.32.0

################################################################################
# build settings

# How many cores to use during compile
NPROC 	= $(shell nproc 2> /dev/null || echo 1)
# NPROC 	= 1

################################################################################
# FSBL settings
FBSL_CFLGAS	= -DFSBL_DEBUG_INFO

################################################################################
# UBOOT settings
UBOOT_CFLAGS = -DDEBUG

# for boot.bin
UBOOT_LOAD		= 0x100000
UBOOT_STARTUP	= 0x100000

################################################################################
# linux settings
LINUX_CFLAGS = 

# load address is where the kernel gets extracted to by u boot
LINUX_LOAD_ADR	= 0x8000
# entry point after kernel extraction
LINUX_ENTRY_ADR	= 0x8000

################################################################################
# Executables
RM 		= rm -rf
VIVADO 	= vivado -nolog -nojournal -mode batch
XSCT 	= xsct
TEST 	= echo main

################################################################################
# Output files
XSA   		= build/$(NAME).xsa
PS7INIT_TCL	= build/ps7_init.tcl
FSBL_PROJ	= build/$(NAME).fsbl
FSBL   		= build/$(NAME).fsbl/executable.elf
BOOTBIN 	= build/$(NAME).boot/boot.bin
BOOTBIF 	= build/$(NAME).boot/boot.bif
UBOOT 		= build/$(NAME).uboot/u-boot.bin
UBOOT_ELF	= build/$(NAME).uboot/u-boot.elf
UBOOT_SCR	= build/$(NAME).uboot/boot.scr
UBOOT_UENV	= build/$(NAME).uboot/uEnv.txt
LINUX_UIMAGE	= build/$(NAME).linux/uImage
DTREE_SYSTEM	= build/$(NAME).dtree/system/system-top.dts
DTREE_USER		= build/$(NAME).dtree/$(notdir $(DTREE_USER_SRC))
DTREE_DTB 		= build/$(NAME).dtree/devicetree.dtb
BUILDROOT_UINITRD	= build/$(NAME).buildroot/uInitrd
BUSYBOX_UINITRD		= build/$(NAME).busybox/uInitrd

# files to put on sd boot partition
SD_BOOT_CONTENTS	= $(BOOTBIN) $(UBOOT_SCR) $(UBOOT_UENV) \
	$(LINUX_UIMAGE) $(DTREE_DTB) 

################################################################################
# Errors
$(XPR):
	$(error Vivado HLx project not found.)

################################################################################
# XSA and FSBL
FSBL_DIR = fsbl
include $(FSBL_DIR)/fsbl.make
xsa: $(XSA)
fsbl-proj: $(FSBL_PROJ)
fsbl: $(FSBL)

################################################################################
# uboot bootloader
UBOOT_DIR = uboot
include $(UBOOT_DIR)/uboot.make

################################################################################
# linux kernel
LINUX_DIR = linux
include $(LINUX_DIR)/linux.make

################################################################################
# device tree
DTREE_DIR = dtree
include $(DTREE_DIR)/dtree.make

################################################################################
# BOOT binay
BOOTBIN_DIR = bootbin
include $(BOOTBIN_DIR)/bootbin.make
bootbin: $(BOOTBIN)
bootbif: $(BOOTBIF)

################################################################################
# buildroot
ifeq ($(INIT_CHOICE), buildroot)
BUILDROOT_DIR = buildroot
SD_BOOT_CONTENTS += $(BUILDROOT_UINITRD)
include $(BUILDROOT_DIR)/buildroot.make
endif

################################################################################
# busybox
ifeq ($(INIT_CHOICE), busybox)
BUSYBOX_DIR = busybox
SD_BOOT_CONTENTS += $(BUSYBOX_UINITRD)
include $(BUSYBOX_DIR)/busybox.make
endif


################################################################################
# JTAG utilities
run-fsbl: $(FSBL) $(PS7INIT_TCL)
	$(XSCT) scripts/jtag_run_elf.tcl $(FSBL)
run-uboot: $(UBOOT_ELF) $(PS7INIT_TCL)
	$(XSCT) scripts/jtag_run_elf.tcl $(UBOOT_ELF)


################################################################################
# SDCARD utilities
sdcard: $(SD_BOOT_CONTENTS)
	rm -r build/$(NAME).sdcard
	mkdir -p build/$(NAME).sdcard
	cp -v $(SD_BOOT_CONTENTS) build/$(NAME).sdcard
