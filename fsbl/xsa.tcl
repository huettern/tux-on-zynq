# @Author: noah
# @Date:   2020-08-31 14:01:33
# @Last Modified by:   noah
# @Last Modified time: 2020-08-31 14:02:08

# Exports xsa hardware definition from vivado hlx project

set xsa           [lindex $argv 0]
set xpr           [lindex $argv 1]

open_project $xpr

write_hw_platform -fixed -force -file $xsa

close_project
