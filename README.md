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