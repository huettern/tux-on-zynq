# @Author: noah
# @Date:   2020-08-31 13:51:00
# @Last Modified by:   noah
# @Last Modified time: 2020-08-31 14:07:08

# Generates source code for a first stage bootloader

set project_name [lindex $argv 0]
set proc_name [lindex $argv 1]
set xsa [lindex $argv 2]
set fsbl_path [lindex $argv 3]

file mkdir build/$project_name.fsbl
file copy -force $xsa build/$project_name.fsbl/$project_name.xsa

hsi open_hw_design build/$project_name.fsbl/$project_name.xsa
hsi create_sw_design -proc $proc_name -os standalone fsbl

hsi add_library xilffs
hsi add_library xilrsa

hsi generate_app -proc $proc_name -app zynq_fsbl -dir $fsbl_path

hsi close_hw_design [hsi current_hw_design]
