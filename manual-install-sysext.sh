#! /bin/bash

## we need a way to automate checking for version bumps
NETFILTER_VER="1.2.6"
LIBEDIT_VER="20230828-3.1"
NFTABLES_VER="1.0.9"
AUDIT_VER="3.1.2"
LZ4_VER="1.9.4"
LIBCBOR_VER="0.10.2"
LIBMICROHTTPD_VER="0.9.77"
KEXEC_VER="2.0.27"
LIBBPF_VER="1.2.2"
LIBFIDO2_VER="1.13.0"
QUOTA_VER="4.09"
TPM2_VER="4.0.1"
ELFUTILS_VER="0.189"
SQUASHFS_VER="4.6.1"
IUCODE_VER="2.3.1"
MICROCODE_VER="20230808"
DRACUT_VER="059"
GNUEFI_VER="3.0.17"
HELP2MAN_VER="1.49.3"
RDFIND_VER="1.6.0"
FIRMWARE_VER="20231030"
SYSTEMD_VER="254"

cd /sources
wget -N https://www.netfilter.org/pub/libnftnl/libnftnl-$NETFILTER_VER.tar.xz
wget -N https://thrysoee.dk/editline/libedit-$LIBEDIT_VER.tar.gz
wget -N https://www.netfilter.org/pub/nftables/nftables-$NFTABLES_VER.tar.xz
wget -N https://github.com/linux-audit/audit-userspace/archive/refs/tags/v$AUDIT_VER.tar.gz -O /sources/audit.tar.gz
wget -N https://github.com/lz4/lz4/archive/refs/tags/v$LZ4_VER.tar.gz -O lz4.tar.gz
wget -N https://github.com/PJK/libcbor/archive/refs/tags/v$LIBCBOR_VER.tar.gz -O libcbor.tar.gz
wget -N https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-$LIBMICROHTTPD_VER.tar.gz
wget -N https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kexec/kexec-tools-$KEXEC_VER.tar.xz
wget -N https://github.com/libbpf/libbpf/archive/refs/tags/v$LIBBPF_VER.tar.gz -O libbpf.tar.gz
wget -N https://developers.yubico.com/libfido2/Releases/libfido2-$LIBFIDO2_VER.tar.gz
wget -N https://sourceforge.net/projects/linuxquota/files/quota-tools/$QUOTA_VER/quota-$QUOTA_VER.tar.gz
wget -N https://github.com/tpm2-software/tpm2-tss/releases/download/$TPM2_VER/tpm2-tss-$TPM2_VER.tar.gz
wget -N https://github.com/plougher/squashfs-tools/archive/refs/tags/$SQUASHFS_VER.tar.gz -O squashfs.tar.gz
wget -N https://gitlab.com/iucode-tool/releases/raw/master/iucode-tool_$IUCODE_VER.tar.xz
wget -N https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/archive/refs/tags/microcode-$MICROCODE_VER.tar.gz
wget -N https://github.com/dracutdevs/dracut/archive/refs/tags/$DRACUT_VER.tar.gz -O dracut.tar.gz
wget -N https://sourceforge.net/projects/gnu-efi/files/gnu-efi-$GNUEFI_VER.tar.bz2
wget -N https://ftp.gnu.org/gnu/help2man/help2man-$HELP2MAN_VER.tar.xz
wget -N https://http://rdfind.pauldreik.se/rdfind-$RDFIND_VER.tar.gz
wget -N https://mirrors.edge.kernel.org/pub/linux/kernel/firmware/linux-firmware-$FIRMWARE_VER.tar.xz


cd /tmp
tar xf /sources/libnftnl-$NETFILTER_VER.tar.xz
cd /tmp/libnftnl-$NETFILTER_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/libedit-$LIBEDIT_VER.tar.gz
cd /tmp/libedit-$LIBEDIT_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/nftables-$NFTABLES_VER.tar.xz
cd /tmp/nftables-$NFTABLES_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/audit.tar.gz
cd /tmp/audit-userspace-$AUDIT_VER
    ./autogen.sh && ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/lz4.tar.gz
cd /tmp/lz4-$LZ4_VER
    make PREFIX=/usr && make PREFIX=/usr install
cd /tmp
tar xf /sources/libcbor.tar.gz
cd /tmp/libcbor-$LIBCBOR_VER
    mkdir build && cd build &&
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr ../ &&
    make && make install
cd /tmp
tar xf /sources/libmicrohttpd-$LIBMICROHTTPD_VER.tar.gz
cd /tmp/libmicrohttpd-$LIBMICROHTTPD_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/kexec-tools-$KEXEC_VER.tar.xz
cd /tmp/kexec-tools-$KEXEC_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/libbpf.tar.gz
cd /tmp/libbpf-$LIBBPF_VER
    cd src
    sed -i  's/lib64/lib/g' Makefile &&
    make && make install
cd /tmp
tar xf /sources/libfido2-$LIBFIDO2_VER.tar.gz
cd /tmp/libfido2-$LIBFIDO2_VER
    mkdir build && cd build &&
    cmake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr ../ &&
    make && make install
cd /tmp
tar xf /sources/elfutils-$ELFUTILS_VER.tar.bz2
cd /tmp/elfutils-$ELFUTILS_VER
    ./configure --prefix=/usr --disable-debuginfod && make && make install
cd /tmp
tar xf /sources/quota-$QUOTA_VER.tar.gz
cd /tmp/quota-$QUOTA_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/tpm2-tss-$TPM2_VER.tar.gz
cd /tmp/tpm2-tss-$TPM2_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/squashfs.tar.gz
cd /tmp/squashfs-tools-$SQUASHFS_VER
    cd squashfs-tools &&
    sed -i -e 's/#XZ_SUPPORT/XZ_SUPPORT/g' -e 's/#LZO_SUPPORT/LZO_SUPPORT/g' -e 's/#LZ4_SUPPORT/LZ4_SUPPORT/g' -e 's/#ZSTD_SUPPORT/ZSTD_SUPPORT/g' -e 's/usr\/local/usr/g' -e '/..\/generate-manpages/d' Makefile &&
    make && make install
cd /tmp
tar xf /sources/iucode-tool_$IUCODE_VER.tar.xz
cd /tmp/iucode-tool-$IUCODE_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/microcode-$MICROCODE_VER.tar.gz
cd /tmp/Intel-Linux-Processor-Microcode-Data-Files-microcode-$MICROCODE_VER
    rm -f intel-ucode{,-with-caveats}/list &&
    mkdir -p kernel/x86/microcode &&
    iucode_tool --write-earlyfw=intel-ucode.img intel-ucode{,-with-caveats}/ &&
    mv -v intel-ucode.img /efi/
cd /tmp
tar xf /sources/dracut.tar.gz
cd /tmp/dracut-$DRACUT_VER
    ./configure --prefix=/usr --disable-documentation && make && make install
cd /tmp
tar xf /sources/gnu-efi-$GNUEFI_VER.tar.bz2
cd /tmp/gnu-efi-$GNUEFI_VER
    LDFLAGS="" make PREFIX=/usr && make PREFIX=/usr install
cd /tmp
tar xf /sources/help2man-$HELP2MAN_VER.tar.xz
cd /tmp/help2man-$HELP2MAN_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/rdfind-$RDFIND_VER.tar.gz
cd /tmp/rdfind-$RDFIND_VER
    ./configure --prefix=/usr && make && make install
cd /tmp
tar xf /sources/linux-firmware-$FIRMWARE_VER.tar.xz
cd /tmp/linux-firmware-$FIRMWARE_VER
    mkdir -p kernel/x86/microcode &&
    cat amd-ucode/microcode_amd*.bin > kernel/x86/microcode/AuthenticAMD.bin &&
    echo kernel/x86/microcode/AuthenticAMD.bin |     bsdtar --uid 0 --gid 0 -cnf - -T - |     bsdtar --null -cf - --format=newc @- > amd-ucode.img &&
    mv amd-ucode.img /efi &&
    ZSTD_CLEVEL=19 make FIRMWAREDIR=/usr/lib/firmware install-zst
cd /tmp
git clone https://git.kernel.org/pub/scm/linux/kernel/git/jejb/sbsigntools.git
cd /tmp/sbsigntools
    git submodule init
    ./autogen.sh
    ./configure --prefix=/usr && make && make install
cd /tmp
git clone https://github.com/Soviet-Linux/neofetch.git
cd /tmp/neofetch
    make DESTDIR=/var/lib/extensions/neofetch install
    mkdir -p /var/lib/extensions/neofetch/usr/lib/extension-release.d
    cat > /var/lib/extensions/neofetch/usr/lib/extension-release.d/extension-release.neofetch << EOF
    NAME=neofetch
    ID=sovietlinux
    VERSION_ID=$LFS_BUILD
    PRETTY_NAME="Soviet Linux - Neofetch"
    ANSI_COLOR="0;31"
    HOME_URL="https://sovietlinux.org"
    VARIANT="systext Neofetch"
    VARIANT_ID=$LFS_BUILD
EOF
git clone https://github.com/Soviet-Linux/libspm.git
cd /tmp/libspm
    make all
    make formats
    make test
    make PREFIX=/usr install
cd /tmp
git clone https://github.com/Soviet-Linux/CCCP.git
cd /tmp/CCCP
    make PREFIX=/usr install
pip3 install pefile
pip3 install pyelftools

cd /tmp
tar xf /sources/systemd-$SYSTEMD_VER.tar.gz
cd /tmp/systemd-$SYSTEMD_VER
mkdir build && cd build &&
meson setup \
-Dmode=release \
-Dlink-udev-shared=true \
-Dlink-systemctl-shared=true \
-Dlink-networkd-shared=true \
-Dlink-timesyncd-shared=true \
-Dlink-journalctl-shared=true \
-Dlink-boot-shared=true \
-Dlink-portabled-shared=true \
-Dfirst-boot-full-preset=true \
-Dnscd=true \
-Ddefault-dnssec=no \
-Ddefault-locale='C.UTF-8' \
-Dukify=true \
-Dbootloader=true \
-Dfallback-hostname='sovietlinux' \
-Dsbat-distro-summary='Soviet Linux' \
-Dsbat-distro-version='Vanguard' \
-Dsbat-distro-url='https://sovietlinux.org' \
-Dbpf-framework=true \
      ..
ninja
ninja install
