# soviet-generate-scripts

*These scripts are in a very early stage, and are full of bad code. Use at your own risk.*

Terms:  
    **LFS** - Linux From Scratch  
    **BLFS** - Beyond Linux From Scratch  
    **ALFS** - Automated Linux from Scratch  
    **jhalfs** - the script run by ALFS  
    More information about these can be found at https://linuxfromscratch.org  
    **nspawn** - systemd-nspawn is an advanced chroot style program - https://wiki.archlinux.org/title/Systemd-nspawn for more info.
    
The scripts primarily function as a wrapper around the pre-existing ALFS and BLFS scripts. This requires some modification of the ALFS and BLFS files, and is an ongoing project to make it reliable against changes from upstream.

## overview
The main file is *lfs-generate.sh.* It's the only file that the user should need to configure and run, and should exit with a completed soviet build, including the downloadable content. *lfs-generate* itself calls 4 scripts that create the soviet build:
- lfs-base-install.sh
- lfs-prep-ext.sh
- lfs-extended.sh
- lfs-cleanup.sh

**lfs-base-install.sh** is itself a wrapper around the ALFS script. It modifies the jhalfs script to remove all the user input, and uses a pre-built configuration file. It also modifies several of the programs that are installed to better fit the *soviet* layout.  
**lfs-prep.ext.sh** copies all the necessary files for the BLFS stage into the new LFS build, created in the *lfs-base-install* stage.  
**lfs-extended.sh** installs ~55 programs using the BLFS scripts, and another ~20 manually installed files. These are a variety of useful utilities, and functionality for systemd.  
**lfs-cleanup.sh** adds a small number of files that couldn't be added during *lfs-prep-ext,* and removes all build files from the final soviet build.

## layout
This script uses 2 full linux builds to create the 3rd, new *soviet* build:
- the host distro, which runs *lfs-generate.sh, lfs-prep-ext.sh,* and *lfs-cleanup.sh*
- a pre-existing *soviet* release to run *lfs-base-install.sh*. This is located within the host file system.
- The new *soviet* build runs *lfs-extended.sh* within it's own nspawn. This is inside the pre-existing *soviet* distro.

The layout looks like this (default example):
```
Host System
|_ (base filesystem)
    |_ soviet-builder (holds all the files)
        |_ lfs-generate.sh
        |_ soviet-generate-scripts (this repository)
        |_ sovietlinux-23xxxx (pre-existing soviet bulid)
            |_ soviet-build (all the other scripts will be put here)
                |_ build-23xxxx (the new soviet build)
```
The *preparation* instructions below assume you're using this layout.

The reason for the pre-existing *soviet* layer:  
To generate the base LFS system (which is done in _lfs-base-install.sh_) ALFS requires a non-root user with sudo access to work. The default ALFS script will ask several times for your password to elevate privileges.  
However, since we want an unmonitored script that needs no human intervention, we have two options: add the user password to the scripts so it can be fed to the sudo request when asked, or make a user with NOPASSWD:ALL access that can run commands without asking. Neither option is good for your host system.

The solution I've chosen is to use the *pre-existing* Soviet Linux build, put the NOPASSWD:ALL user inside the _soviet_ build, and nspawn into that for _lfs-base-install.sh._ This user has root-level access to the nspawn system so it still has security concerns, but your host system will be safe.


## preparation
The following is required before invoking the _lfs-generate.sh_ script:
- Your host system needs to have the programs necessary to create a LFS build. See https://linuxfromscratch.org/lfs/view/systemd/chapter02/hostreqs.html for more info.
- You need a _soviet_ release. Check our Discord in \#testing-releases channel to find the most recent available: https://discord.gg/ZmYAmAXvtX . Grab the *sovietlinux-\*-full.tar.xz* file.

Create your setup:
- create *soviet-builder* somewhere in your host system.
 - In this directory, git clone the *soviet-generate-scripts* repo ( `git clone https://github.com/tbeckerson/soviet-generate-scripts.git`)
- copy *soviet-generate-scripts/lfs-generate.sh* into the *soviet-builder* directory.
 - edit the three variables at the beginning of *lfs-generate.sh*
 - make a subdirectory *sovietlinux-23xxxx*.
  - extract the *\*-full.tar.xz* file into it.
- *systemd-nspawn* into the *sovietlinux-23xxxx* directory (as root or sudo, `systemd-nspawn -bD /path/to/sovietlinux-23xxxx` user root, password sovietlinux).
 - in the */soviet-build* directory, clone a fresh version of jhalfs (the ALFS build script): `git clone https://git.linuxfromscratch.org/jhalfs.git jhalfs`
 - create a new group and user named *sovietbuilder*, no special setup required ( `groupadd sovietbuilder; useradd sovietbuilder`)
 - write a new file named */etc/sudoers.d/10-sovietbuilder* with the following content: `sovietbuilder ALL=(ALL) NOPASSWD:ALL`
 - give *sovietbuilder* ownership of all the files in *soviet-build* ( `chown -R sovietbuilder:sovietbuilder /soviet-build`)
 - `poweroff` to exit the nspawn (this does not shut off your computer, despite how it looks.)
- now back in the host system, create a directory name *sovietlinux-23xxxx/soviet-build*.
 - Copy the files from *soviet-generate-scripts* into it.

## running the scripts
As root, invoking *lfs-generate.sh* should be all that's needed. The script should allow you to resume at the beginning of each stage of the build. A file *build-time* is generated, with the start and finish times.

## TODO:
### high priority
- dig thorough the ALFS code and remove the parts that require being a non-root user, so the entire middle layer distro can be removed.
- finer grained error handling in *lfs-extended.sh*, the BLFS and manual installs overwrite your progress and re-install everything in their lists.
### medium priority
- some of the seds use line numbers - this could be a problem if the file is changed.
- better notifications about what the script is doing at any given time. maybe a spinner instead of stdout?
- maybe some colours?
### low priority
- uses sed for everything, because that's what LFS uses. But maybe some awk lines would be better?
- mabye remove some of the seds swap in a pre-made file?
- need to properly comment what sgdisk is doing in *lfs-generate*.
