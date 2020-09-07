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

## Literature

On minimal linux systems with kernel & initramfs:
- https://medium.com/@kiky.tokamuro/creating-initramfs-5cca9b524b5a
- https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e

Zynq Linux device drivers:
- https://www.youtube.com/watch?v=h-ZP98qhEM8

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

From this declaration we find that `#address-cells = <1>` meaning that any child-node must define a `reg` with one address cell and zero size cells `#size-cells = <0>`. The PHY address is specified in the datasheet. In my case, the address can be configured with package pins, but the schematic doesn't show this connection. After running u-boot without the reg declaration, the `mii info` command listed the PHY:

```
PHY 0x03: OUI = 0x0885, Model = 0x22, Rev = 0x02, 100baseT, FDX
```

A read at the device identifier address, shows the correct phy:
```
zturn> mii read 3 0x2-0x3
addr=03 reg=02 data=0022
addr=03 reg=03 data=1622
```

We can now append information to the `gem0` node to get the PHY running:

```dts
&gem0 {
	status = "okay";
	phy-mode = "rgmii-id";
	phy-handle = <&ethernet_phy>;

	ethernet_phy: ethernet-phy@0 {
		reg = <3>;
		compatible = "micrel,ksz9031";
		device_type = "ethernet-phy";
	};
};
```


### JTAG debugging in console
The `ps7_init.tcl` can be extracted from the `xsa` zip file. Some commands can be found [here](https://www.xilinx.com/html_docs/xilinx2017_4/SDK_Doc/xsct/use_cases/xsct_use_cases.html).

**Set boot mode to JTAG**