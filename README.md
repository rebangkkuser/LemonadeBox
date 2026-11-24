# LemonadeBox

For compilling:
```bash
./build.sh
```
Needed toolchain:
- gcc/clang
- ld/ld.lld
- binutils
- make
- git
- any libc (will static compile) we reccomend glibc
- ncurses (only for menuconfig. optional)

The result will be:
lemonadebox.tar.xz (rootfs tarball)
lemonade/ (rootfs dir)

> [!IMPORTANT] Warning
> This project *will not* be responsable with any damage or thermonuclear wars
> because /dev, /proc or /sys explosion. the chroot maybe need to bind these

To start chroot:
```bash
sudo mount --rbind /dev (rootfs)/dev
sudo mount --bind /sys (rootfs)/sys
sudo mount --bind /proc (rootfs)/proc
env -i sudo chroot (chroot) /bin/busybox ash
```
For unmounting, run
```bash
sudo umount -l (rootfs)/dev
sudo umount -l (rootfs)/sys
sudo umount -l (rootfs)/proc
```
