#! /bin/bash

## stop immediately if something doesn't work
set -e

## figure out how to identify a target, or get user to input it
## and use $1 to pass it to $TARGET
TARGET="$1"
## parse the os-release file for a date
LFS_BUILD="$(grep VERSION_ID= /etc/os-release | sed 's/VERSION_ID=//')"

## partition the target drive
sgdisk -n 1:0:+512M -c 1:"SOVIET-EFI" -t 1:ef00 -n 2:0:0 -c 2:"sovietlinux" -t2:8304 $TARGET

## format the new partitions
mkfs.vfat ${TARGET}1 -F 32 -n SOVIET-EFI
mkfs.btrfs ${TARGET}2 -L sovietlinux
## mount the btrfs partition
mount ${TARGET}2 -o compress=zstd /mnt
## make our new subvolumes
## yes, the usr subvolume has the . to hide it by default
btrfs subvolume create /mnt/soviet-rootfs
btrfs subvolume create /mnt/soviet-rootfs/.usr-$LFS_BUILD
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/var
## make directories to hold our new subvolumes
mkdir /mnt/soviet-rootfs/{efi,home,usr,var}

## unmount the partition, then remount the subvolumes
umount /mnt
mount LABEL=sovietlinux -o compress=zstd,subvol=soviet-rootfs /mnt
mount LABEL=sovietlinux -o compress=zstd,subvol=soviet-rootfs/.usr-$LFS_BUILD /mnt/usr
mount LABEL=sovietlinux -o compress=zstd,subvol=home /mnt/home
mount LABEL=sovietlinux -o compress=zstd,subvol=var /mnt/var

## get the EFI partition mounted
mount LABEL=SOVIET-EFI /mnt/efi

## copy soviet to the new partitions
echo 'installing Soviet Linux to your drive! Please be patient' 
cp -Rv /run/rootfsbase/* /mnt
rm /mnt/etc/soviet-install.sh

## inject the final steps in this script
cat > /mnt/soviet-final.sh << "EOF"
#! /bin/bash

## parse the kernel version
KVER=$(uname -r)
## parse the os-release file for a date
## this var needs to be re-created for this script
LFS_BUILD="$(grep VERSION_ID= /etc/os-release | sed 's/VERSION_ID=//')"
cd /
## get a fresh machine-id
systemd-machine-id-setup
## core customizations
systemd-firstboot --setup-machine-id --prompt-locale --prompt-timezone --prompt-keymap --prompt-hostname --prompt-root-password --root-shell=/bin/bash --force
## use the systemd-provided keys for systemd-sysupdate
echo 'Adding gpg keys for A/B updates (gpg --import /lib/systemd/import-pubring.gpg)'
gpg --import /lib/systemd/import-pubring.gpg
## systemd recommends this to avoid disk thrashing
chattr +C /var/log/journal
## new initrd using host-only to reduce size
dracut -H -I ' /usr/bin/nano ' --add-fstab ' /etc/fstab-231112 ' --strip /tmp/sov-initrd.img
## new uki with the new initrd
/usr/lib/systemd/ukify build --linux=/usr/lib/modules/${KVER}/vmlinuz-soviet-$LFS_BUILD --initrd=/tmp/sov-initrd.img --uname=${KVER} --splash=/efi/logo-soviet-boot.bmp --cmdline=@/etc/kernel/cmdline --output=/efi/EFI/Linux/sovietlinux-$LFS_BUILD-initrd.efi
## fresh random seed
bootctl random-seed
EOF
chmod +x /mnt/soviet-final.sh

## start an nspawn, run the above script
systemd-nspawn -D /mnt --as-pid2 /soviet-final.sh

## get rid of the temp script when done
rm /mnt/soviet-final.sh

## all done!
while true; do

read -p "Installation complete! Do you want to reboot, poweroff, or quit to shell? (r/p/q) " rpq
case $rpq in 
	[rR] ) echo rebooting!;
		systemctl reboot;;
	[pP] ) echo shutting down!;
		systemctl poweroff;;
	[qQ] ) echo quitting to prompt;

		exit;;
	* ) echo invalid response;;
esac
done
