
################################################################################
# upstream
UBOOT_TAR = build/$(NAME).uboot/$(UBOOT_TAG).tar.gz
UBOOT_REPO = build/$(NAME).uboot/u-boot-xlnx-$(UBOOT_TAG)
UBOOT_REPO_STMP	= build/$(NAME).uboot/u-boot-xlnx-$(UBOOT_TAG)/.stmp
UBOOT_URL = https://github.com/Xilinx/u-boot-xlnx/archive/$(UBOOT_TAG).tar.gz

# u boot build products
UBOOT_CONFIG 	= $(UBOOT_REPO)/.config

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
uboot-repo: $(UBOOT_REPO_STMP)
$(UBOOT_REPO_STMP): $(UBOOT_TAR) boards/$(BOARD)/$(UBOOT_DEFCONFIG)
	mkdir -p $(UBOOT_REPO)
	tar -zxf $< --strip-components=1 --directory=$(UBOOT_REPO)
	cp boards/$(BOARD)/$(UBOOT_DEFCONFIG) $(UBOOT_REPO)/configs/$(notdir $(UBOOT_DEFCONFIG))
	cp boards/$(BOARD)/$(UBOOT_DTS) $(UBOOT_REPO)/arch/arm/dts/$(notdir $(UBOOT_DTS))
	sed -i '/^dtb-$$(CONFIG_ARCH_ZYNQ).*/a $(patsubst %.dts,%.dtb,$(notdir $(UBOOT_DTS))) \\' $(UBOOT_REPO)/arch/arm/dts/Makefile
	touch $(UBOOT_REPO_STMP)

uboot-xconfig: $(UBOOT_REPO_STMP)
	make -C $(UBOOT_REPO) ARCH=arm CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) xconfig
uboot-menuconfig: $(UBOOT_REPO_STMP)
	make -C $(UBOOT_REPO) ARCH=arm CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) menuconfig
uboot-mrproper:
	make -C $(UBOOT_REPO) ARCH=arm CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) mrproper
uboot-configure: $(UBOOT_CONFIG)
$(UBOOT_CONFIG): $(UBOOT_REPO_STMP)
	make -C $(UBOOT_REPO) ARCH=arm CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) \
		$(notdir $(UBOOT_DEFCONFIG))

# configure uboot
uboot: $(UBOOT) $(UBOOT_SCR) $(UBOOT_UENV)
$(UBOOT): $(UBOOT_REPO_STMP)
	make -C $(UBOOT_REPO) -j$(NPROC) ARCH=arm CFLAGS="$(UBOOT_CFLAGS)" CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) \
		all
	cp $(UBOOT_REPO)/u-boot.bin $@

$(UBOOT_ELF): $(UBOOT)
	cp $(UBOOT_REPO)/u-boot.elf $(dir $@)	

clean-uboot-repo:
	$(RM) $(UBOOT_REPO)

# Creates the boot.scr file that gets loaded by u boot
$(UBOOT_SCR): boards/$(BOARD)/$(UBOOT_SCR_SRC)
	mkimage -A arm -T script -O linux -C none -n "u-boot environment" \
		-d boards/$(BOARD)/$(UBOOT_SCR_SRC) $(UBOOT_SCR)

# uEnv.txt file
$(UBOOT_UENV): boards/$(BOARD)/$(UBOOT_UENV_SRC)
	cp boards/$(BOARD)/$(UBOOT_UENV_SRC) $(UBOOT_UENV)
