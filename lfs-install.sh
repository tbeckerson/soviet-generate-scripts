#! /bin/bash

## This script should be in /mnt/lfs/lfs-current, relative to the
## host system. It'll be executed inside an nspawn environment

## the directory containing the whole project - probably /lfs?
LFS_DIR="/lfs"
## establish a build number
## get value from lfs-build, create it if needed
if [ -f "$LFS_DIR/lfs-build" ]; then
LFS_BUILD="$(cat "$LFS_DIR/lfs-build")"
else
echo "$(date +%y%m%d)" > $LFS_DIR/lfs-build
fi

## where the magic happens. A full directory with build number
## /lfs/build-xxxxxx for example
LFS_BUILD_DIR="$LFS_DIR/build-$LFS_BUILD"
## the jhalfs directory outside the build dir
JHALFS_DIR="$LFS_DIR/jhalfs"
## the jhalfs dir inside the build
JHALFS_BUILD_DIR="$LFS_BUILD_DIR/jhalfs"
## where BLFS resides
BLFS_DIR="$LFS_BUILD_DIR/blfs_root"

## make sure build directory exists, create it if not
if [ ! -d "$LFS_BUILD_DIR" ]; then
sudo -u lfs mkdir -p $LFS_BUILD_DIR
fi


## figure out the number of available processors,
## set LFS to use procs -1 so the system still has resources
NPROCS=$(nproc)
if [ $NPROCS -eq 1 ]
then
MAKEFLAGS=" -j1 "; PARALLEL="1"
else
MAKEFLAGS=" -j$((NPROCS-1))"; PARALLEL="$((NPROCS-1))"
fi


## stage 1 - prep jhalfs and build the basic system
if [ ! -f "$LFS_BUILD_DIR/stage1-complete" ]; then
sudo -u lfs $LFS_DIR/lfs-stage1.sh
fi

## stage 2 - add files for systemd-nspawn
if [ ! -f "$LFS_BUILD_DIR/stage2-complete" ]; then
$LFS_DIR/lfs-stage2.sh
fi
## stage 3 - inside systemd-nspawn
if [ ! -f "$LFS_BUILD_DIR/stage3-complete" ]; then
systemd-nspawn -D $LFS_BUILD_DIR --as-pid2 /lfs-stage3.sh
fi
## stage 4 - move out unwanted files
$LFS_DIR/lfs-stage4.sh &&

## leave the nspawn, back to lfs-generate.sh
printf "exit \n"
