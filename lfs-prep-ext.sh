#! /bin/bish

## this file is executed from the host directory

## stop immediately if something breaks
set -e

## where to find the BLFS files
BLFS_DIR=$LFS_BUILD_DIR/blfs_root

## indicate what stage we're on
echo "Preparing for extended build - moving and updating files"
sleep 2

## avoid some 'safe path transitions' errors later
chown root:root $LFS_BUILD_DIR
cd $LFS_DIR
## profile
cp -v profile $LFS_BUILD_DIR/etc
## for systemd-networkd
cp -v 10-dhcp.network 20-wifi.network $LFS_BUILD_DIR/etc/systemd/network/
cp -v networkd.conf $LFS_BUILD_DIR/etc/systemd/
## for systemd-sysupdate
cp -v 50-usr.conf 60-efi.conf $LFS_BUILD_DIR/etc/sysupdate.d/
## for the UKIs
cp -v cmdline cmdline-installer $LFS_BUILD_DIR/etc/kernel/
# update fstab-install to correct name
cp -v fstab-install $LFS_BUILD_DIR/etc/fstab-$LFS_BUILD
sed -i "s/23xxxx/$LFS_BUILD/" $LFS_BUILD_DIR/etc/fstab-$LFS_BUILD
## update content of os-release
cp -v os-release $LFS_BUILD_DIR/usr/lib/
sed -i "s/23xxxx/$LFS_BUILD/" $LFS_BUILD_DIR/usr/lib/os-release
## the loader config for systemd-boot
cp -v loader.conf $LFS_BUILD_DIR/efi/loader/
echo type2 >> $LFS_BUILD_DIR/efi/loader/entries.srel
## zram support
cp -v zramswap.conf $LFS_BUILD_DIR/etc/
cp -v zramctl $LFS_BUILD_DIR/etc/systemd/system/
cp -v zramswap.service $LFS_BUILD_DIR/usr/lib/systemd/system/zramswap.service
## fix problems with LFS's /etc/hosts problem by letting systemd
## manage the network
cp -v hosts $LFS_BUILD_DIR/etc

## os-release and localtime should be relative symlinks, so
## remove default files, re-link with custom work
cd $LFS_BUILD_DIR/etc
rm os-release localtime
ln -s ../usr/lib/os-release
ln -s ../usr/share/zoneinfo/UTC localtime

cd $LFS_DIR

## add some missing files that stop nscd from working
echo -e "f /run/nscd/nscd.pid 0755 root root\nf /run/nscd/service 0755 root root" >> $LFS_BUILD_DIR/usr/lib/tmpfiles.d/nscd.conf
touch $LFS_BUILD_DIR/etc/netgroup

## get blfs ready to pop
cp -v blfs-configuration $BLFS_DIR/configuration
sed -i "s/JOBS=XX/JOBS=$PARALLEL/" $BLFS_DIR/configuration
## the stage3 build script
cp -v lfs-build $LFS_BUILD_DIR
cp -v lfs-extended.sh $LFS_BUILD_DIR
cp -v manual-install.sh $LFS_BUILD_DIR
cp -v logo-soviet-boot.bmp $LFS_BUILD_DIR/efi

touch $LFS_DIR/prep-complete
