
# Configuration file for boot bin generator
$(BOOTBIF):
	mkdir -p $(@D)
	$(RM) $(BOOTBIF)
	@echo "img: {" >> $(BOOTBIF)
	@echo "  [bootloader] $(FSBL)" >> $(BOOTBIF)
	# Check for other existing binaries to put into boot.bin

	# [ ] bitstream
	test -e $(BIT) && echo "  $(BIT)" >> $(BOOTBIF) || :

	# [ ] second stage bootloader
	echo "  [load=$(UBOOT_LOAD),startup=$(UBOOT_STARTUP)] $(UBOOT)" >> $(BOOTBIF)

	@echo "}" >> $(BOOTBIF)

# Generate actual boot binary
$(BOOTBIN): $(BOOTBIF) $(FSBL) $(UBOOT)
	bootgen -image $(BOOTBIF) -w -o i $@
