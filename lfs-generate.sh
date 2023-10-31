#! /bin/bash

## this file resides in a 'lfs' directory in the host system

## the structure:
#  /path/to/lfs <-- host system where we start
#   |_ lfs-current <-- $LFS_NSPAWN, symlink to nspawn system
#       |_lfs <-- $LFS_DIR containing files for new system
#           |_ build-xxxxxx <-- $LFS_BUILD_DIR, new system
##
## start us off by tracking the overall time taken
echo "Started: $(date)" > build-time

## the directory containing the soviet build we'll be nspawning into
LFS_NSPAWN="/mnt/storage/lfs/lfs-current"
LFS_DIR="$LFS_NSPAWN/lfs"
## website location for update files
UPDATE_DIR="/srv/"

## figure out the number of available processors,
## set to procs -1 so the system still has resources
NPROCS=$(nproc)
if [ $NPROCS -eq 1 ]
then
PARALLEL="1"
else
PARALLEL="$((NPROCS-1))"
fi

## whole thing starts with nspawn command
## this will take hours and go on it's own quest
if [ ! -f $LFS_DIR/base-complete ]; then
systemd-nspawn -D $LFS_NSPAWN -u sovietbuilder /lfs/lfs-base-install.sh
echo "Base Install Finished: $(date)" >> build-time
fi

## Get the LFS_BUILD variable, which was created in stage 1
if [ -f $LFS_DIR/base-complete ]; then
LFS_BUILD="$(cat $LFS_DIR/lfs-build)"
LFS_BUILD_DIR="$LFS_DIR/build-$LFS_BUILD"
fi

## move files to build dir
if [ -f $LFS_DIR/base-complete ] && [ ! -f $LFS_DIR/prep-complete ]; then
source $LFS_DIR/lfs-prep-ext.sh
echo "BLFS Preperation Finished: $(date)" >> build-time
fi

## comes back, goes right in again to deeper level
## get LFS_BUILd
if [ -f $LFS_DIR/prep-complete ] && [ ! -f $LFS_BUILD_DIR/extended-complete ]; then
systemd-nspawn -D $LFS_BUILD_DIR /lfs-extended.sh
echo "BLFS and UKI Finished: $(date)" >> build-time
fi


## cleanup
if [ -f $LFS_BUILD_DIR/extended-complete ] && [ ! -f $LFS_DIR/cleanup-complete ]; then
source $LFS_DIR/lfs-cleanup.sh
echo "Cleanup Finished: $(date)" >> build-time
fi

## continue with making update images
if [ -f $LFS_DIR/cleanup-complete ]; then
echo 'Soviet $LFS_BUILD built successfully! Now making user files'
fi

## when the above finishes (hours later), there should be a complete
## Soviet build in $SOV_BUILD_DIR, with a date stated in the
## lfs-build file

## where the xz, img, and other completed files are stored
SOV_BUILD_FILES="$LFS_DIR/$LFS_BUILD-files"

## squashfs img
cd $LFS_BUILD_DIR
mksquashfs ./* $SOV_BUILD_FILES/squashfs.img -b 1M -noappend
## compressed files
tar -vcf $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-core.tar ./*
tar -vcf $SOV_BUILD_FILES/usr-$LFS_BUILD.tar ./usr/*
## quicker to use xz separately, because multi-threading
cd $SOV_BUILD_FILES
xz -vT $PARALLEL sovietlinux-$LFS_BUILD-core.tar
xz -vT $PARALLEL usr-$LFS_BUILD.tar

## installer img
cd $SOV_BUILD_FILES
## dirs for the img
mkdir $SOV_BUILD_FILES/loop-efi
mkdir $SOV_BUILD_FILES/loop-install
## make the img and give it a loop device
truncate -s 1330M $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-installer.img
## this creates the loop device, and grabs the /dev it's assigned to #
LOOP="$(losetup -fP $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-installer.img --show)"
## sgdisk to create partitions
sgdisk -n 1:0:+95M -c 1:"SOV-EFI" -t 1:ef00 -n 2:0:0 -c 2:"soviet-install" -t2:8304 $LOOP
## make filesystems
mkfs.vfat -F 32 -n SOV-EFI ${LOOP}p1 
mkfs.btrfs -f -L soviet-install ${LOOP}p2 
## mount the partitions
mount -o loop ${LOOP}p1 $SOV_BUILD_FILES/loop-efi/
mount -o loop,compress=zstd ${LOOP}p2 $SOV_BUILD_FILES/loop-install/
## pull in the efi directory
cp -Rv $LFS_BUILD_DIR/efi/* $SOV_BUILD_FILES/loop-efi/
## ...but not the generic efi
rm -v $SOV_BUILD_FILES/loop-efi/EFI/Linux/sovietlinux-$LFS_BUILD-initrd.efi
## instead we want the special installer efi
cp -v $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-installer.efi $SOV_BUILD_FILES/loop-efi/EFI/Linux/
## make a home for the squashfs.img and copy it to installer
mkdir $SOV_BUILD_FILES/loop-install/LiveOS
cp -v $SOV_BUILD_FILES/squashfs.img $SOV_BUILD_FILES/loop-install/LiveOS/squashfs.img

## unmount and disconnect the loop device
umount loop-efi
umount loop-install
losetup -d $LOOP

cp -v $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-installer.img $UPDATE_DIR
cp -v $SOV_BUILD_FILES/sovietlinux-$LFS_BUILD-core.tar.xz $UPDATE_DIR
cp -v $SOV_BUILD_FILES/usr-$LFS_BUILD.tar.xz $UPDATE_DIR
cp -v $SOV_BUILD_FILES/fstab-$LFS_BUILD $UPDATE_DIR

## NEED TO ADD CHECKSUM AND GPG FILES!! Another script??

## Now that we're done, delete the lfs-build file and the *-complete
## files so it'll generate a new build next time
rm $LFS_DIR/{base,prep,cleanup}-complete
rm $LFS_DIR/lfs-build

echo "Soviet Linux $LFS_BUILD is complete!"

echo "Generation Finished: $(date)" >> build-time
