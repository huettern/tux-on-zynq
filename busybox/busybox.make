
################################################################################
# upstream
BUSYBOX_TAR	= build/$(NAME).busybox/busybox-$(BUSYBOX_TAG).tar.bz2
BUSYBOX_REPO 	= build/$(NAME).busybox/busybox-$(BUSYBOX_TAG)
BUSYBOX_REPO_STMP	= build/$(NAME).busybox/busybox-$(BUSYBOX_TAG)/.stmp
BUSYBOX_URL	= https://busybox.net/downloads/busybox-$(BUSYBOX_TAG).tar.bz2

# build products
BUSYBOX_INSTALL_PATH = build/$(NAME).busybox/install
BUSYBOX_BINARY	= $(BUSYBOX_REPO)/busybox
BUSYBOX_INSTALL	= $(BUSYBOX_REPO)/install/bin/busybox
BUSYBOX_UINITRD	= build/$(NAME).busybox/uInitrd
BUSYBOX_INITRAMFS	= build/$(NAME).busybox/initramfs.img

################################################################################
# settings
BUSYBOX_CFLAGS += -O2 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard
BUSYBOX_CROSS_COMPILE	= arm-linux-gnueabihf-

################################################################################
# phony targets
.PHONY: busybox-tar busybox-repo busybox-menuconfig busybox-mrproper 
.PHONY:	clean-busybox-repo busybox-all

################################################################################
# downloads
busybox-tar: $(BUSYBOX_TAR)
$(BUSYBOX_TAR):
	mkdir -p $(@D)
	curl -L $(BUSYBOX_URL) -o $@

################################################################################
# untar config patch

# untar and copy defconfig
busybox-repo: $(BUSYBOX_REPO_STMP)
$(BUSYBOX_REPO_STMP): $(BUSYBOX_TAR) boards/$(BOARD)/$(BUSYBOX_DEFCONFIG)
	mkdir -p $(BUSYBOX_REPO)
	tar -xf $(BUSYBOX_TAR) --strip-components=1 --directory=$(BUSYBOX_REPO)
	cp boards/$(BOARD)/$(BUSYBOX_DEFCONFIG) $(BUSYBOX_REPO)/.config
	touch $(BUSYBOX_REPO_STMP)

################################################################################
# config build
busybox-menuconfig: $(BUSYBOX_REPO_STMP)
	make -C $(BUSYBOX_REPO) ARCH=arm CROSS_COMPILE=$(BUSYBOX_CROSS_COMPILE) menuconfig
busybox-mrproper:
	make -C $(BUSYBOX_REPO) ARCH=arm CROSS_COMPILE=$(BUSYBOX_CROSS_COMPILE) mrproper

# run buildroot
busybox-all: $(BUSYBOX_BINARY)
$(BUSYBOX_BINARY): $(BUSYBOX_REPO_STMP)
	make -C $(BUSYBOX_REPO) ARCH=arm CROSS_COMPILE=$(BUSYBOX_CROSS_COMPILE) \
		defconfig
	make -C $(BUSYBOX_REPO) -j$(NPROC) ARCH=arm CROSS_COMPILE=$(BUSYBOX_CROSS_COMPILE) \
		CFLAGS="$(BUSYBOX_CFLAGS)" all

busybox-install: $(BUSYBOX_INSTALL)
$(BUSYBOX_INSTALL): $(BUSYBOX_BINARY)
	mkdir -p $(BUSYBOX_INSTALL_PATH)
	make -C $(BUSYBOX_REPO) -j$(NPROC) ARCH=arm CROSS_COMPILE=$(BUSYBOX_CROSS_COMPILE) \
		CFLAGS="$(BUSYBOX_CFLAGS)" CONFIG_PREFIX=install install
	cp -av $(BUSYBOX_REPO)/install/. $(BUSYBOX_INSTALL_PATH)

# generate bootable image for u boot
busybox-uinitrd: $(BUSYBOX_UINITRD)
$(BUSYBOX_UINITRD): $(BUSYBOX_INSTALL) busybox/genfs.sh
	sh busybox/genfs.sh $(BUSYBOX_INSTALL_PATH) boards/$(BOARD)/$(BUSYBOX_RCS)
	cd $(BUSYBOX_INSTALL_PATH) && find . | cpio -o --format=newc > ../initramfs.img
	mkimage -A arm -T ramdisk -C gzip -n "Busybox rootfs" \
		-d $(BUSYBOX_INITRAMFS) $(BUSYBOX_UINITRD)

################################################################################
# clean
clean-busybox-repo:
	$(RM) $(BUSYBOX_REPO)


################################################################################
# utils
