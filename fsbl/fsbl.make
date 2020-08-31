
################################################################################
# Exports xsa hardware platform from vivado hlx project
$(XSA):
	mkdir -p $(@D)
	# Args: xsa xpr
	$(VIVADO) -source $(FSBL_DIR)/xsa.tcl -tclargs $(XSA) $(XPR)

################################################################################
# Create first stage bootloader
$(FSBL_PROJ): $(XSA)
	mkdir -p $(@D)
	# 	project_name proc_name xsa fsbl_path
	$(XSCT) $(FSBL_DIR)/fsbl.tcl $(NAME) $(PROC) $(XSA) $(FSBL_PROJ)
# 	patch -d $(@D) < patches/fsbl/fsbl.patch

################################################################################
# Compile first stage bootloader
$(FSBL): $(FSBL_PROJ)
	make CFLAGS=$(FBSL_CFLGAS) -C $(FSBL_PROJ)
