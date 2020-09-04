
################################################################################
# upstream
BUILDROOT_TAR	= build/$(NAME).buildroot/buildroot-$(BUILDROOT_TAG).tar.bz2
BUILDROOT_REPO 	= build/$(NAME).buildroot/buildroot-$(BUILDROOT_TAG)
BUILDROOT_REPO_STMP	= build/$(NAME).buildroot/buildroot-$(BUILDROOT_TAG)/.stmp
BUILDROOT_URL	= https://buildroot.org/downloads/buildroot-$(BUILDROOT_TAG).tar.bz2

# build products
BUILDROOT_CONFIG 	= $(BUILDROOT_REPO)/.config
BUILDROOT_ROOTFS	= $(BUILDROOT_REPO)/output/images/rootfs.cpio

################################################################################
# settings
BUILDROOT_CFLAGS 		+= -O2 -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
BUILDROOT_CROSS_COMPILE	= arm-linux-gnueabihf-

################################################################################
# phony targets
.PHONY: buildroot-tar buildroot-repo buildroot-xconfig buildroot-menuconfig buildroot-mrproper 
.PHONY:	buildroot-configure buildroot-savedefconfig clean-buildroot-repo buildroot-all

################################################################################
# downloads
buildroot-tar: $(BUILDROOT_TAR)
$(BUILDROOT_TAR):
	mkdir -p $(@D)
	curl -L $(BUILDROOT_URL) -o $@

################################################################################
# untar config patch

# untar and copy defconfig
buildroot-repo: $(BUILDROOT_REPO_STMP)
$(BUILDROOT_REPO_STMP): $(BUILDROOT_TAR) boards/$(BOARD)/$(BUILDROOT_DEFCONFIG)
	mkdir -p $(BUILDROOT_REPO)
	tar -xf $(BUILDROOT_TAR) --strip-components=1 --directory=$(BUILDROOT_REPO)
	cp boards/$(BOARD)/$(BUILDROOT_DEFCONFIG) $(BUILDROOT_REPO)/configs/$(notdir $(BUILDROOT_DEFCONFIG))
	touch $(BUILDROOT_REPO_STMP)

################################################################################
# config build
buildroot-xconfig: $(BUILDROOT_REPO_STMP)
	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) xconfig
buildroot-menuconfig: $(BUILDROOT_REPO_STMP)
	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) menuconfig
buildroot-mrproper:
	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) mrproper
buildroot-savedefconfig: $(BUILDROOT_REPO_STMP)
	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) savedefconfig
	@echo "Configuration written to $(BUILDROOT_REPO)/defconfig"

buildroot-configure: $(BUILDROOT_CONFIG)
$(BUILDROOT_CONFIG): $(BUILDROOT_REPO_STMP)
	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) \
		$(notdir $(BUILDROOT_DEFCONFIG))

# run buildroot
buildroot-all: $(BUILDROOT_ROOTFS)
$(BUILDROOT_ROOTFS): $(BUILDROOT_CONFIG)
	LD_LIBRARY_PATH= make -C $(BUILDROOT_REPO) -j$(NPROC) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) \
		CFLAGS="$(BUILDROOT_CFLAGS)" all

# # build device tree compiler
# $(DTC): $(BUILDROOT_REPO_STMP) $(BUILDROOT_CONFIG)
# 	make -C $(BUILDROOT_REPO) ARCH=arm CROSS_COMPILE=$(BUILDROOT_CROSS_COMPILE) \
# 		CFLAGS="$(BUILDROOT_CFLAGS)" scripts_dtc

# generate bootable image for u boot
buildroot-uimage: $(BUILDROOT_UIMAGE)
$(BUILDROOT_UIMAGE): $(BUILDROOT_ROOTFS)
	mkimage -A arm -T ramdisk -C gzip -n "Buildroot rootfs" \
		-d $(BUILDROOT_ROOTFS) $(BUILDROOT_UIMAGE)

################################################################################
# clean
clean-buildroot-repo:
	$(RM) $(BUILDROOT_REPO)


################################################################################
# utils
