# @Author: Noah Huetter
# @Date:   2020-09-01 10:21:37
# @Last Modified by:   Noah Huetter
# @Last Modified time: 2020-09-01 10:22:02

# Connects to ARM through JTAG and downloads the provided elf

set elf [lindex $argv 0]

# connect to debugger
connect

# change target to CPU0
targets -set -filter {name =~ "ARM* #0"}

# init ps7
source build/ps7_init.tcl
ps7_init
ps7_post_config

# download fsbl, sets PC to reset
dow $elf

# continue program execution
con
