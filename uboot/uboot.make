
################################################################################
# upstream
UBOOT_TAR = build/$(NAME).uboot/$(UBOOT_TAG).tar.gz
UBOOT_REPO = build/$(NAME).uboot/u-boot-xlnx-$(UBOOT_TAG)
UBOOT_URL = https://github.com/Xilinx/u-boot-xlnx/archive/$(UBOOT_TAG).tar.gz

################################################################################
# settings
UBOOT_CFLAGS 		+= -O2 -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
UBOOT_CROSS_COMPILE	= arm-linux-gnueabihf-

################################################################################
# targets
uboot-tar: $(UBOOT_TAR)
$(UBOOT_TAR):
	mkdir -p $(@D)
	curl -L $(UBOOT_URL) -o $@

# untar and patch uboot
uboot-repo: $(UBOOT_REPO)
$(UBOOT_REPO): $(UBOOT_TAR)
	mkdir -p $@
	tar -zxf $< --strip-components=1 --directory=$@
	cp boards/$(BOARD)/$(UBOOT_DEFCONFIG) $@/configs/$(notdir $(UBOOT_DEFCONFIG))
	cp boards/$(BOARD)/$(UBOOT_DTS) $@/arch/arm/dts/$(notdir $(UBOOT_DTS))
	sed -i '/^dtb-$$(CONFIG_ARCH_ZYNQ).*/a $(patsubst %.dts,%.dtb,$(notdir $(UBOOT_DTS))) \\' $@/arch/arm/dts/Makefile

# configure uboot
uboot: $(UBOOT) $(UBOOT_SCR) $(UBOOT_UENV)
$(UBOOT): $(UBOOT_REPO)
	make -C $< ARCH=arm $(notdir $(UBOOT_DEFCONFIG))
	make -C $< ARCH=arm CFLAGS="$(UBOOT_CFLAGS)" \
		-j$(NPROC)  \
		CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) all
	cp $</u-boot.bin $@

$(UBOOT_ELF): $(UBOOT)
	cp $(UBOOT_REPO)/u-boot.elf $(dir $@)	

clean-uboot-repo:
	$(RM) $(UBOOT_REPO)

# Creates the boot.scr file that gets loaded by u boot
$(UBOOT_SCR): boards/$(BOARD)/$(UBOOT_SCR_SRC)
	mkimage -A arm -T script -O linux -C none -d boards/$(BOARD)/$(UBOOT_SCR_SRC) $(UBOOT_SCR)

# uEnv.txt file
$(UBOOT_UENV): boards/$(BOARD)/$(UBOOT_UENV_SRC)
	cp boards/$(BOARD)/$(UBOOT_UENV_SRC) $(UBOOT_UENV)
