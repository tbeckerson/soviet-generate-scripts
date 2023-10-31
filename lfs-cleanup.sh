#! /bin/bash

## this file is executed from the host directory

## stop immediately if something breaks
set -e

## indicate what stage we're on
echo "Cleaning up the new build"
sleep 1

cd $LFS_DIR
## create a build file storage if it doesn't exist
if [ ! -d "$LFS_DIR/$LFS_BUILD" ]; then
mkdir $LFS_DIR/$LFS_BUILD-files
fi

## copy the generic efi
cp -v $LFS_BUILD_DIR/efi/EFI/Linux/sovietlinux-* $LFS_BUILD-files/
## move the dracut imgs and the installer efi out of system
mv $LFS_BUILD_DIR/efi/sovietlinux-* $LFS_BUILD-files/
## no longer needed, only there to create the install efi
rm -v $LFS_BUILD_DIR/etc/kernel/cmdline-installer
## list of installed packages
mv $LFS_BUILD_DIR/var/lib/jhalfs/BLFS/instpkg.xml $LFS_BUILD-files/
## systemd install places this, is a non-working template
rm -v $LFS_BUILD_DIR/etc/systemd/network/10-eth-static.network
cp -v networkd.conf $LFS_BUILD_DIR/etc/systemd/
## remove lsb-release, supplanted by os-release
rm -v $LFS_BUILD_DIR/etc/lsb-release
## systemd-boot files
cp -v $LFS_BUILD_DIR/usr/lib/systemd/boot/efi/systemd-bootx64.efi $LFS_BUILD_DIR/efi/EFI/BOOT/BOOTX64.EFI
cp -v $LFS_BUILD_DIR/usr/lib/systemd/boot/efi/systemd-bootx64.efi $LFS_BUILD_DIR/efi/EFI/systemd/
## copy fstab to build directory
cp -v $LFS_BUILD_DIR/etc/fstab-$LFS_BUILD $LFS_BUILD-files/
## add optional soviet-install.sh to build
cp -v $LFS_DIR/soviet-install.sh $LFS_BUILD_DIR/etc/
chmod +x $LFS_BUILD_DIR/etc/soviet-install.sh

## machine-id file needs to be made on a per-install basis to be unique
echo uninitialized > $LFS_BUILD_DIR/etc/machine-id
## faster than excluding the 'remote' directory
rm -rfv $LFS_BUILD_DIR/var/log/journal/[a-z]*
mkdir $LFS_BUILD_DIR/var/log/journal/remote
## LFS BUILD files and leftover files from nspawn
rm -rfv -rfv $LFS_BUILD_DIR/blfs_root
rm -rfv -rfv $LFS_BUILD_DIR/jhalfs
rm -rfv -rfv $LFS_BUILD_DIR/var/lib/jhalfs
rm -rfv -rfv $LFS_BUILD_DIR/sources
rm -rfv -rfv $LFS_BUILD_DIR/root/.[a-z]*
rm -rfv -rfv $LFS_BUILD_DIR/usr/share/doc/*
rm -rfv -rfv $LFS_BUILD_DIR/tmp/*
rm -v $LFS_BUILD_DIR/etc/fstab
rm -v $LFS_BUILD_DIR/manual-install.sh
rm -v $LFS_BUILD_DIR/lfs-extended.sh
rm -v $LFS_BUILD_DIR/lfs-build
rm -v $LFS_BUILD_DIR/blfs-complete
rm -v $LFS_BUILD_DIR/manual-complete
rm -v $LFS_BUILD_DIR/extended-complete

touch $LFS_DIR/cleanup-complete
