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
scripts/config -e STATIC
echo "Setting up wget and sha256sum on busybox config..."
scripts/config -e WGET
scripts/config -e FEATURE_WGET_HTTPS
scripts/config -e FEATURE_WGET_TIMEOUT
scripts/config -e SHA256SUM
scripts/config -e TAR
scripts/config -e XZ
echo "Disabling tc because Linux 6.8 removed CBQ"
scripts/config -d TC
grep -q '^CONFIG_STATIC=y' .config || {
    echo "Static binary not enabled!"
    exit 1
}
make olddefconfig
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
