#!/bin/bash

set -e

BUSYBOX_DIR=$1
INIT_SCRIPT=$2

cd $BUSYBOX_DIR

# Create requierd directories
mkdir -p dev 
mkdir -p etc etc/init.d 
mkdir -p mnt opt proc root 
mkdir -p sys tmp var var/log

# remove rc and link to busybox
rm -f ./linuxrc
# ln -s ./bin/busybox ./init

# create fstab
cat << EOF > ./etc/fstab
LABEL=/     /           tmpfs   defaults        0 0
none        /dev/pts    devpts  gid=5,mode=620  0 0
none        /proc       proc    defaults        0 0
none        /sys        sysfs   defaults        0 0
none        /tmp        tmpfs   defaults        0 0
EOF

# create inittab
cat << EOF > ./etc/inittab
::sysinit:/etc/init.d/rcS
# /bin/ash
# 
# Start an askfirst shell on the serial ports
ttyPS0::respawn:-/bin/ash

# What to do when restarting the init process
::restart:/sbin/init

# What to do before rebooting
::shutdown:/bin/umount -a -r
EOF

# Create rcS script
cat << EOF > ./etc/init.d/rcS
#!/bin/sh

echo "Starting rcS..."

echo "++ Mounting filesystem"
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp

echo "++ Setting up mdev"

echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s

echo "rcS Complete"
EOF
chmod 755 ./etc/init.d/rcS

# create password file
cat << EOF > ./etc/passwd
root:x:0:0:root:/root:/bin/sh
EOF

# change file id of busybox
sudo chown 0:0 ./bin/busybox

echo "Busybox file system ready at $BUSYBOX_DIR"
