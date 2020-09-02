
################################################################################
# upstream
LINUX_TAR 	= build/$(NAME).linux/linux-$(LINUX_TAG).tar.xz
LINUX_SIGN 	= build/$(NAME).linux/linux-$(LINUX_TAG).sign
LINUX_REPO 	= build/$(NAME).linux/linux-$(LINUX_TAG)
LINUX_REPO_STMP	= build/$(NAME).linux/linux-$(LINUX_TAG)/.stmp
LINUX_URL 	= https://cdn.kernel.org/pub/linux/kernel/$(LINUX_MAJOR)/linux-$(LINUX_TAG).tar.xz
LINUX_SIGN_URL	= https://cdn.kernel.org/pub/linux/kernel/$(LINUX_MAJOR)/linux-$(LINUX_TAG).sign

# linux build products
LINUX_CONFIG 	= $(LINUX_REPO)/.config
LINUX_ZIMAGE	= $(LINUX_REPO)/arch/arm/boot/zImage

################################################################################
# settings
LINUX_CFLAGS 		+= -O2 -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
LINUX_CROSS_COMPILE	= arm-linux-gnueabihf-

################################################################################
# phony targets
.PHONY: linux-tar linux-repo linux-xconfig linux-menuconfig linux-mrproper 
.PHONY:	linux-configure linux-savedefconfig linux-zimage linux-uimage clean-linux-repo

################################################################################
# downloads
linux-tar: $(LINUX_TAR)
$(LINUX_TAR):
	mkdir -p $(@D)
	curl -L $(LINUX_URL) -o $@

$(LINUX_SIGN):
	mkdir -p $(@D)
	curl -L $(LINUX_SIGN_URL) -o $@

################################################################################
# untar config patch

# untar and copy defconfig
linux-repo: $(LINUX_REPO_STMP)
$(LINUX_REPO_STMP): $(LINUX_TAR) $(LINUX_SIGN) boards/$(BOARD)/$(LINUX_DEFCONFIG)
	mkdir -p $(LINUX_REPO)
	tar -xf $(LINUX_TAR) --strip-components=1 --directory=$(LINUX_REPO)
	cp boards/$(BOARD)/$(LINUX_DEFCONFIG) $(LINUX_REPO)/arch/arm/configs/$(notdir $(LINUX_DEFCONFIG))
	touch $(LINUX_REPO_STMP)

################################################################################
# config build
linux-xconfig: $(LINUX_REPO_STMP)
	make -C $(LINUX_REPO) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) xconfig
linux-menuconfig: $(LINUX_REPO_STMP)
	make -C $(LINUX_REPO) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) menuconfig
linux-mrproper:
	make -C $(LINUX_REPO) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) mrproper
linux-configure: $(LINUX_CONFIG)
$(LINUX_CONFIG): $(LINUX_REPO_STMP)
	make -C $(LINUX_REPO) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) \
		$(notdir $(LINUX_DEFCONFIG))
linux-savedefconfig: $(LINUX_REPO_STMP)
	make -C $(LINUX_REPO) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) savedefconfig
	@echo "Configuration written to $(LINUX_REPO)/defconfig"

# build linux
linux-zimage: $(LINUX_ZIMAGE)
$(LINUX_ZIMAGE): $(LINUX_REPO_STMP) $(LINUX_CONFIG)
	make -C $(LINUX_REPO) -j$(NPROC) ARCH=arm CROSS_COMPILE=$(LINUX_CROSS_COMPILE) \
		CFLAGS="$(LINUX_CFLAGS)" zImage

# generate bootable image for u boot
linux-uimage: $(LINUX_UIMAGE)
$(LINUX_UIMAGE): $(LINUX_ZIMAGE)
	mkimage -A arm -O linux -T kernel -C none \
		-a $(LINUX_LOAD_ADR) -e $(LINUX_ENTRY_ADR) -n "Linux kernel $(LINUX_TAG)"\
		-d $(LINUX_REPO)/arch/arm/boot/zImage $(LINUX_UIMAGE)


################################################################################
# clean

clean-linux-repo:
	$(RM) $(LINUX_REPO)


################################################################################
# utils
