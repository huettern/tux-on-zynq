
################################################################################
# Project settings

# Project name
NAME	= zturn

# Path to the vivado project
XPR		= $$HOME/git/zynq-sandbox/fpga/hlx/build/projects/zturn-lcd-vdma.xpr

# Path to the hlx bitstream if exists
# BIT		= 
BIT		= $$HOME/git/zynq-sandbox/fpga/hlx/build/projects/zturn-lcd-vdma.runs/impl_1/system_wrapper.bit

# Processor to use for FSBL
PROC 	= ps7_cortexa9_0

################################################################################
# FSBL settings
FBSL_CFLGAS	= -DFSBL_DEBUG_INFO

################################################################################
# UBOOT settings

# for boot.bin
UBOOT_LOAD		= 0x100000
UBOOT_STARTUP	= 0x100000

################################################################################
# Executables
RM 		= rm -rf
VIVADO 	= vivado -nolog -nojournal -mode batch
XSCT 	= xsct
TEST 	= echo main

################################################################################
# Output files
XSA   		= build/$(NAME).xsa
FSBL_PROJ	= build/$(NAME).fsbl
FSBL   		= build/$(NAME).fsbl/executable.elf
BOOTBIN 	= build/$(NAME).boot/boot.bin
BOOTBIF 	= build/$(NAME).boot/boot.bif
UBOOT 		= build/$(NAME).uboot/u-boot.elf

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
# BOOT binay
BOOTBIN_DIR = bootbin
include $(BOOTBIN_DIR)/bootbin.make
bootbin: $(BOOTBIN)
bootbif: $(BOOTBIF)