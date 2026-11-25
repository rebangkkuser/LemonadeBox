#!/bin/bash

set -euo pipefail

echo "Settuping BusyBox variables..."
export BB_EXTRA_VERSION="-LemonadeBox-0.1"

echo "Verifying kernel..."
if [ ! $(uname -s) = Linux ]; then
	echo "Kernel is not Linux! Refusing to compile."
	exit 1
fi

echo "Building BusyBox..."

cd external/busybox
make defconfig

echo "Configuring BusyBox..."

set_config() {
    local option="$1"
    local value="$2"

    if grep -q "^CONFIG_${option}=" .config; then
        sed -i "s/^CONFIG_${option}=.*/CONFIG_${option}=${value}/" .config
    else
        sed -i "/^# CONFIG_${option} is not set/d" .config
        echo "CONFIG_${option}=${value}" >> .config
    fi
}

set_config STATIC y
set_config WGET y
set_config FEATURE_WGET_HTTPS y
set_config FEATURE_WGET_TIMEOUT y

echo "Disabling TC..."
set_config TC n
grep -q '^CONFIG_STATIC=y' .config || {
    echo "Static binary not enabled!"
    exit 1
}
make oldconfig
make -j$(nproc)

echo "Making rootfs dir on lemonade/..."
cd ../..
mkdir -p lemonade
mkdir -p lemonade/bin
mkdir -p lemonade/lib
mkdir -p lemonade/tmp
mkdir -p lemonade/root
mkdir -p lemonade/etc
cp external/busybox/busybox lemonade/bin/busybox

echo "Installing BusyBox binaries..."
echo "Not cross compilling, so, using QEMU not needed"
cd lemonade/bin
./busybox --install -s .
cd ../..

echo "Putting os-release on rootfs"
cat << EOF >lemonade/etc/os-release
NAME="LemonadeBox"
PRETTY_NAME="LemonadeBox 0.1"
ID=lemonadebox
ID_LIKE=linux
VERSION="0.1"
VERSION_ID="0.1"
VERSION_CODENAME=lemonjuice
HOME_URL="https://github.com/rebangkkuser/LemonadeBox"
SUPPORT_URL="https://github.com/rebangkkuser/LemonadeBox/issues"
BUG_REPORT_URL="https://github.com/rebangkkuser/LemonadeBox/issues"
LOGO=lemonadebox
EOF
echo "Adding shadow, group and passwd"
cat << EOF > lemonade/etc/passwd
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
EOF

cat << EOF > lemonade/etc/group
root:x:0:
nogroup:x:65534:
EOF

cat << EOF > lemonade/etc/shadow
root:x:0:
nogroup:x:65534:
EOF

chmod 600 lemonade/etc/shadow

echo "Compressing rootfs..."
tar -cJf lemonadebox.tar.xz -C . lemonade/
echo "Done!"
exit
