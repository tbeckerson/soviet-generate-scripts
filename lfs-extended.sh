#! /bin/bash

## this script is run as a nspawn inside of the new build at
## LFS_BUILD_DIR/build-xxxxxx

## stop immediately if something breaks
set -e
## checks for the BUILD number sent in from prep stage
LFS_BUILD="$(cat lfs-build)"
## the directory containing the BLFS content 
BLFS_DIR="/blfs_root"
## figure out the number of available processors,
## set LFS to use procs -1 so the system still has resources
NPROCS=$(nproc)
if [ $NPROCS -eq 1 ]
then
MAKEFLAGS=" -j1 " PARALLEL="1"
else
MAKEFLAGS=" -j$((NPROCS-1))"; PARALLEL="$((NPROCS-1))"
fi

## for the blfs systemd service files
## need a way to parse this automatically
SYSTEMD_UNITS_VER=20230816
## for the UKI
KVER=$(grep VERSION= /jhalfs/lfs-commands/chapter10/1002-kernel | sed 's/VERSION=//')

## START! ##
## indicate what stage we're on
echo "Extended Build - BLFS and UKI"
sleep 2

## add a check in case of failure
if [ ! -f /blfs-complete ]; then
	echo 'blfs-complete file is missing, building BLFS programs'
	sleep 2
	## start in the blfs_root dir
	cd $BLFS_DIR

	## get rid of the verification step that seeks input
	sed -i '/echo "\${SD_BORDER}/,/echo "\${nl_}\${SD_BORDER}/{/^/d}' $BLFS_DIR/gen_pkg_book.sh
	## fire up the BLFS script to read the config and make an install list
	$BLFS_DIR/gen_pkg_book.sh 
	## create the work directory if it isn't there
		if [ ! -d work ]; then
		mkdir work
		fi
	cd work

	## TODO: need a check to see if a BLFS build is already in progress
	## prepare and execute the BLFS makefile
	$BLFS_DIR/gen-makefile.sh

	## fix some scripts that will cause build failures

	## the blfs-systemd-units often don't download and extract properly.
	## we'll do it manually after this
	sed -i '/BOOTPKG_DIR=blfs-systemd-units/,/popd/{/^/d}' $BLFS_DIR/scripts/{*acpid,*cyrus-sasl,*openldap,*openssh,*rsync}
	## slapd runs a test that we're not using,
	## and breaks build sometimes
	sed -i '/systemctl start slapd/,/ldapsearch/{/^/d}' $BLFS_DIR/scripts/*openldap
	## ssh-keygen this requires user intervention,
	## and shouldn't be installed be default anyway
	sed -i '/ssh-keygen/,/ssh-copy-id/{/^/d}' $BLFS_DIR/scripts/*openssh
	## polkit defaults to needing introspection,
	## which we don't want to install by default
	sed -i '/-Dsession_tracking/ a -Dintrospection=false \\' $BLFS_DIR/scripts/*polkit
	## sqlite docs package often has a bad md5 sum (why tho?),
	## and we're deleting the docs later anyway to save space
	## so this purges them from the build
	sed -i '/\<PACKAGE1\>/,/SRC_DIR/{/^/d}' $BLFS_DIR/scripts/*sqlite
	sed -i '/unzip -q \.\.\/sqlite-doc-3430200.zip/d' $BLFS_DIR/scripts/*sqlite
	sed -i '/install -v -m755 -d \/usr\/share\/doc\/sqlite-3.43.2/d' $BLFS_DIR/scripts/*sqlite
	sed -i '/cp -v -R sqlite-doc-3430200\/\* \/usr\/share\/doc\/sqlite-3.43./d' $BLFS_DIR/scripts/*sqlite

## commit!
make
fi
touch /blfs-complete

## get the BLFS systemd service units and intall
cd /sources
wget https://www.linuxfromscratch.org/blfs/downloads/systemd/blfs-systemd-units-$SYSTEMD_UNITS_VER.tar.xz
tar xf blfs-systemd-units-$SYSTEMD_UNITS_VER.tar.xz
cd blfs-systemd-units-$SYSTEMD_UNITS_VER/
make install-acpid
make install-sshd
make install-rsyncd
make install-saslauthd
make install-slapd

## go to / for the rest
cd /

## reset the flags in /etc/profile
sed -i 's/#//' /etc/profile
sed -i '/export PS1 CARCH CHOST MAKEFLAGS EDITOR/d' /etc/profile
source /etc/profile

## the manual installs - kept in another file for convenience (long)
if [ ! -f /manual-complete ]; then
	echo 'manual-complete does not exist, installing extra programs'
	sleep 2
	source /manual-install.sh
fi
touch /manual-complete

## ready for the official boot

## sysext and confext perform the /var/lib/* overlay
systemctl enable systemd-sysext
systemctl enable systemd-confext
## homectl
systemctl enable systemd-homed
## one day, A/B updates
systemctl enable systemd-sysupdate
## downloading more ram
systemctl enable zramswap
## making sure the networking is correct
systemctl enable systemd-networkd
systemctl enable systemd-resolved
## these were added during install, but don't need to be activated
## by default. systemd or user will activate them if needed.
systemctl disable acpid
systemctl disable rsyncd
systemctl disable saslauthd
systemctl disable slapd

## set the root password
echo 'root:sovietlinux' | chpasswd

## UKI
## installer
dracut --kver $KVER  --add livenet --add-drivers ' vfat squashfs btrfs ' --no-early-microcode --strip -I ' /usr/bin/nano ' /efi/sovietlinux-$LFS_BUILD-initrd-installer.img

## standard
dracut --kver $KVER --add-drivers ' overlay ' --no-early-microcode --strip -I ' /usr/bin/nano ' /efi/sovietlinux-$LFS_BUILD-initrd.img

## live
/usr/lib/systemd/ukify build --linux=/usr/lib/modules/$KVER/vmlinuz-soviet-$LFS_BUILD --initrd=/efi/sovietlinux-$LFS_BUILD-initrd-installer.img --uname=$KVER --cmdline=@/etc/kernel/cmdline-installer --splash=/efi/logo-soviet-boot.bmp --output=/efi/sovietlinux-$LFS_BUILD-installer.efi

## standard
/usr/lib/systemd/ukify build --linux=/usr/lib/modules/$KVER/vmlinuz-soviet-$LFS_BUILD --initrd=/efi/sovietlinux-$LFS_BUILD-initrd.img --uname=$KVER --cmdline=@/etc/kernel/cmdline --splash=/efi/logo-soviet-boot.bmp --output=/efi/EFI/Linux/sovietlinux-$LFS_BUILD-initrd.efi 

touch /extended-complete
