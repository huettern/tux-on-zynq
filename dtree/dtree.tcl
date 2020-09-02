set xsa [lindex $argv 0]
set repo_path [lindex $argv 1]
set proc [lindex $argv 2]
set tree_path [lindex $argv 3]
set boot_args [lindex $argv 4]

# Open XSA/HDF file
hsi open_hw_design $xsa

# Set repository path of xilinx devicetree repo
hsi set_repo_path $repo_path

# Create SW design and setup CPU. 
# The -proc option should be followed be one of these values: 
# for Versal "psv_cortexa72_0", for ZynqMP "psu_cortexa53_0", for Zynq-7000 "ps7_cortexa9_0", for Microblaze "microblaze_0".
hsi create_sw_design device-tree -os device_tree -proc $proc

# set some properties
hsi set_property CONFIG.bootargs $boot_args [hsi get_os]

# Generate DTS/DTSI files to folder my_dts where output DTS/DTSI files will be generated
hsi generate_target -dir $tree_path

# Clean up. 
hsi close_sw_design [hsi current_sw_design]
hsi close_hw_design [hsi current_hw_design]
