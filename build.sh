#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOTFS="$ROOT_DIR/lemonade"

echo "Setting up BusyBox variables..."
export BB_EXTRA_VERSION="-LemonadeBox-0.1"

echo "Verifying kernel..."
if [ "$(uname -s)" != "Linux" ]; then
    echo "Kernel is not Linux! Refusing to compile."
    exit 1
fi

echo "Building BusyBox..."
cd "$ROOT_DIR/external/busybox"

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
set_config SHA1_HWACCEL n
set_config TC n

grep -q '^CONFIG_STATIC=y' .config || {
    echo "Static binary not enabled!"
    exit 1
}

make oldconfig
make -j"$(nproc)"

echo "Building OpenSSL..."

OPENSSL_ARCH="${OPENSSL_ARCH:-linux-aarch64}"

cd "$ROOT_DIR/external/openssl"
OPENSSL_PREFIX="$PWD/install"

echo "Target architecture: $OPENSSL_ARCH"

./Configure "$OPENSSL_ARCH" \
    no-shared \
    no-tests \
    --prefix="$OPENSSL_PREFIX"

make -j"$(nproc)"
make install_sw

echo "Creating LemonadeBox rootfs..."

mkdir -p "$ROOTFS"/{bin,lib,include,tmp,root,etc,dev,proc,sys}

echo "Installing OpenSSL..."

cp "$OPENSSL_PREFIX/bin/openssl" "$ROOTFS/bin/"
cp "$OPENSSL_PREFIX"/lib/*.a "$ROOTFS/lib/"
cp -r "$OPENSSL_PREFIX/include/openssl" "$ROOTFS/include/"

echo "OpenSSL completed!"

echo "Installing BusyBox..."

cp "$ROOT_DIR/external/busybox/busybox" "$ROOTFS/bin/busybox"

(
    cd "$ROOTFS/bin"
    ./busybox --install -s
)

echo "BusyBox applets installed!"

echo "Putting os-release on rootfs..."

cat > "$ROOTFS/etc/os-release" <<EOF
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

echo "Adding shadow, group and passwd..."

cat > "$ROOTFS/etc/passwd" <<EOF
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
EOF

cat > "$ROOTFS/etc/group" <<EOF
root:x:0:
nogroup:x:65534:
EOF

cat > "$ROOTFS/etc/shadow" <<EOF
root:x:0:
EOF

chmod 600 "$ROOTFS/etc/shadow"

echo "Compressing rootfs..."

tar -cJf "$ROOT_DIR/lemonadebox.tar.xz" \
    -C "$ROOT_DIR" lemonade/

echo "Done!"
exit 0
