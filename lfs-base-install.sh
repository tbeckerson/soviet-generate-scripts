#! /bin/bash

## this file resides in /mnt/lfs/lfs-current/lfs. It's accessed inside
## the /mnt/lfs/lfs-current nspawn environment, 1 level deep.
## stop immediately if something breaks
set -e

## the directory containing the whole project - probably /lfs?
LFS_DIR="/lfs"
LFS_BUILD="$(date +%y%m%d)"
## where the magic happens. A full directory with build number
## /lfs/build-xxxxxx for example
LFS_BUILD_DIR="$LFS_DIR/build-$LFS_BUILD"
## the jhalfs directory outside the build dir
JHALFS_DIR="$LFS_DIR/jhalfs"
## the jhalfs dir inside the build
JHALFS_BUILD_DIR="$LFS_BUILD_DIR/jhalfs"

## figure out the number of available processors,
## set LFS to use procs -1 so the system still has resources
NPROCS=$(nproc)
if [ $NPROCS -eq 1 ]
then
MAKEFLAGS=" -j1 "; PARALLEL="1"
else
MAKEFLAGS=" -j$((NPROCS-1))"; PARALLEL="$((NPROCS-1))"
fi

## indicate what stage we're on
echo "Starting Base Install - prepare the generic LFS system \
in directory build $LFS_BUILD"
sleep 1

## put "our" copy of jhalfs & config files into dir
cp -v $LFS_DIR/lfs-jhalfs $JHALFS_DIR/jhalfs
cp -v $LFS_DIR/lfs-configuration $JHALFS_DIR/configuration

## opt files
cp -v $LFS_DIR/opt_config $JHALFS_DIR/optimize/
cp -v $LFS_DIR/opt_override $JHALFS_DIR/optimize/
cp -v $LFS_DIR/O2pipex86 $JHALFS_DIR/optimize/opt_config.d/

## make sure configuration file uses the correct folders
## using @ because the $*_DIR variables have forward slashes in them
sed -i "s@BUILDDIR=\"XX\"@BUILDDIR=\"$LFS_BUILD_DIR\"@" $JHALFS_DIR/configuration
sed -i "s@FSTAB=\"XX\"@FSTAB=\"$LFS_DIR\/fstab-empty\"@" $JHALFS_DIR/configuration
sed -i "s@CONFIG=\"XX\"@CONFIG=\"$LFS_DIR\/config-soviet\"@" $JHALFS_DIR/configuration
sed -i "s/N_PARALLEL=XX/N_PARALLEL=$PARALLEL"/ $JHALFS_DIR/configuration

## create the build directory
mkdir -p $LFS_BUILD_DIR

## run jhalfs - make sure the configuration file is up to date!
cd $JHALFS_DIR
./jhalfs run

## FIX ME - DON'T USE RELATIVE DIRECTORIES!
## now we go into the build dir and start altering some LFS defaults
cd $JHALFS_BUILD_DIR

## 401-creatingminlayout - base directories
cat > lfs-commands/chapter04/401-creatingminlayout << "EOF"
#!/bin/bash
set +h
set -e

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
ln -sv usr/$i $LFS/$i
done
ln -sv usr/lib $LFS/lib64
ln -sv lib $LFS/usr/lib64

mkdir -pv $LFS/tools
exit
EOF

## FIX ME! DON'T USE LINE NUMBERS!!
## 504-glibc - get rid of the lib32 vs lib64 check
sed -i '35,41d' lfs-commands/chapter05/504-glibc

## 703-creatingdirs - customize the filesystem
sed -i 's/boot/boot,efi\/{loader,EFI\/{BOOT,Linux,systemd}}/' lfs-commands/chapter07/703-creatingdirs
sed -i 's/{floppy,cdrom}//' lfs-commands/chapter07/703-creatingdirs
sed -i 's/sysconfig/sysconfig,sysupdate.d,systemd\/system\/console-getty.service.d/' lfs-commands/chapter07/703-creatingdirs
sed -i 's/locate/locate,extensions,confexts/' lfs-commands/chapter07/703-creatingdirs


## 803-glibc - it doesn't compile without --enable-cet on Arch, maybe others??
## doesn't hurt to have even if it's not needed
sed -i '/--with-headers=/ a --enable-cet \\' lfs-commands/chapter08/803-glibc

## Kernel version to be installed
KVER=$(grep VERSION= lfs-commands/chapter10/1002-kernel | sed 's/VERSION=//')
## FIX ME! DON'T USE LINE NUMBERS!!
## 1002-kernel - run multi-threaded. this takes enough time as is.
sed -i "39s/make/make $MAKEFLAGS/" lfs-commands/chapter10/1002-kernel
## 1002-kernel - multi-thread the install, and strip the modules to save space
sed -i "40s/make -j1 modules_install/make $MAKEFLAGS INSTALL_MOD_PATH=\"\/usr\" INSTALL_MOD_STRIP=1 modules_install/" lfs-commands/chapter10/1002-kernel

## put the kernel, system.map, and .config in a better spot
## also, don't install the documentation
sed -i "s/boot\/vmlinuz-$KVER-.*-systemd/\/usr\/lib\/modules\/$KVER\/vmlinuz-soviet-$LFS_BUILD/" lfs-commands/chapter10/1002-kernel
sed -i "s/\/boot\/System\.map-.*/\/usr\/lib\/modules\/$KVER\/System\.map-soviet-$LFS_BUILD/" lfs-commands/chapter10/1002-kernel
sed -i "s/\/boot\/config-.*/\/usr\/lib\/modules\/$KVER\/config-soviet-$LFS_BUILD/"  lfs-commands/chapter10/1002-kernel
sed -i '/Documentation \-T/d'  lfs-commands/chapter10/1002-kernel

## the Makefile

## we're not using grub, so not installing it. These commands remove
## all mention of it from the Makefile so it won't error out.
sed -i '0,/860-grub /s///' Makefile
sed -i -r "/860-grub:  859-groff/,/(call housekeeping)/{/^/d}" Makefile
sed -i 's/860-grub/859-groff/' Makefile

## create the build dir if it isn't already there
if [ ! -d "$LFS_BUILD_DIR" ]; then
mkdir $LFS_BUILD_DIR
fi

## assuming it goes correctly, the make will install the whole system,
## including the pre-chosen BLFS progs.
## this part will take HOURS, and will ask to sudo four or five times
make

touch $LFS_DIR/base-complete
echo "$LFS_BUILD" > $LFS_DIR/lfs-build
