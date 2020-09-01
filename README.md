# Tux on Zynq

## U-BOOT

### Templates
The zturn board specific files are largely based upon
- zynq_zed_defconfig found in https://codeload.github.com/Xilinx/u-boot-xlnx/tar.gz/xilinx-v2019.2
- https://github.com/Xilinx/u-boot-xlnx/blob/master/arch/arm/dts/zynq-zed.dts

To change u-boot configuration, run `make uboot-repo` and then change to `build/name.uboot/` and run

```bash
make menuconfig
```

The changes made are stored in `.config`. To export only the values change, run

```bash
make savedefconfig
```

and store the generated `defconfig` file in the corresponding `boards/name/uboot` folder.


## Knowledge

### Device Tree

A good starting point is [here](https://elinux.org/Device_Tree_Usage) with more [here](https://elinux.org/Device_Tree_Mysteries).

#### Example: Ethernet

The ethernet controller did not work on u-boot out of the box. The ethernet phy had to be added to the device tree. Identified as `micrel ksz9031` part on the board, the dts can be modified.

The root dts `zynq-7000.dtsi` included by `zturn_7010.dts` defines the Zynq's integrated ethernet controller as followed:

```dts
/ {
	cpus {
		// ....
	};
	// ....
	amba: amba {
		u-boot,dm-pre-reloc;
		compatible = "simple-bus";
		#address-cells = <1>;
		#size-cells = <1>;
		interrupt-parent = <&intc>;
		ranges;
		// ....
		gem0: ethernet@e000b000 {
			compatible = "cdns,zynq-gem", "cdns,gem";
			reg = <0xe000b000 0x1000>;
			status = "disabled";
			interrupts = <0 22 4>;
			clocks = <&clkc 30>, <&clkc 30>, <&clkc 13>;
			clock-names = "pclk", "hclk", "tx_clk";
			#address-cells = <1>;
			#size-cells = <0>;
		};
		// ....
	};
};
```

Xilinx's Zynq TRM UG585 specifies the ethernet controller at `e000_b000` which coincides with the definition of `gem0`. `gem0` is a label for `ethernet@e000b000` that we can later use to add devices to the ethernet controller.


### JTAG debugging in console
The `ps7_init.tcl` can be extracted from the `xsa` zip file. Some commands can be found [here](https://www.xilinx.com/html_docs/xilinx2017_4/SDK_Doc/xsct/use_cases/xsct_use_cases.html).

**Set boot mode to JTAG**