
################################################################################
# upstream
DTREE_TAR	= build/$(NAME).dtree/device-tree-xlnx-$(DTREE_TAG).tar.gz
DTREE_URL	= https://github.com/Xilinx/device-tree-xlnx/archive/$(DTREE_TAG).tar.gz
DTREE_REPO 	= build/$(NAME).dtree/device-tree-xlnx-$(DTREE_TAG)
DTREE_REPO_STMP	= build/$(NAME).dtree/device-tree-xlnx-$(DTREE_TAG)/.stmp

################################################################################
# settings

################################################################################
# phony targets
.PHONY: dtree-tar dtree-repo dtree-user dtree-system dtree clean-dtb clean-dtree
.PHONY: clean-dtree-system

################################################################################
# downloads
dtree-tar: $(DTREE_TAR)
$(DTREE_TAR):
	mkdir -p $(@D)
	curl -L $(DTREE_URL) -o $@

################################################################################
# untar config patch
dtree-repo: $(DTREE_REPO_STMP)
$(DTREE_REPO_STMP): $(DTREE_TAR)
	mkdir -p $(DTREE_REPO)
	tar -xf $(DTREE_TAR) --strip-components=1 --directory=$(DTREE_REPO)
	touch $(DTREE_REPO_STMP)

# copy user dts
dtree-user: $(DTREE_USER)
$(DTREE_USER): boards/$(BOARD)/$(DTREE_USER_SRC)
	mkdir -p $(dir $(DTREE_USER))
	cp boards/$(BOARD)/$(DTREE_USER_SRC) $(DTREE_USER)

# generate device tree from hardware project and device tree repository
dtree-system: $(DTREE_SYSTEM)
$(DTREE_SYSTEM): $(XSA) $(DTREE_REPO_STMP)
	mkdir -p $(@D)
	$(XSCT) dtree/dtree.tcl $(XSA) $(DTREE_REPO) $(PROC) $(dir $(DTREE_SYSTEM)) $(DTREE_BOOT_ARGS)
	sed -i 's|#include|/include/|' $@
# 	sed -i '/^.*pcw.dtsi.*/a /include/ "boards/$(BOARD)/dts/board.dtsi"' build/zturn-base.tree/system-top.dts
# 	test -f boards/$(BOARD)/dts/devicetree.patch && patch -d build/$(NAME).tree -p 0 || :

# Compile devicetree
dtree: $(DTREE_DTB)
$(DTREE_DTB): $(DTC) $(DTREE_USER) $(DTREE_SYSTEM)
	$(DTC) -I dts -O dtb -o $(DTREE_DTB) \
		-i $(dir $(DTREE_SYSTEM)) \
		-i $(dir $(DTREE_USER)) \
		$(DTREE_SYSTEM)


################################################################################
# config build

################################################################################
# clean
clean-dtb:
	$(RM) $(DTREE_DTB)
clean-dtree:
	$(RM) build/$(NAME).dtree
clean-dtree-system:
	$(RM) $(DTREE_SYSTEM)