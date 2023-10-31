PS1="\[\e[0;96m\]\t \[\e[0;36m\]\u \[\e[0m\][\[\e[0;92m\]\W\[\e[0m\]] \[\e[0m\]\$ \[\e[0m\]"

CARCH="x86_64"
CHOST="x86_64-pc-linux-gnu"

#CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions \
#        -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
#        -fstack-clash-protection -fcf-protection"
#CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
#LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
#LTOFLAGS="-flto=auto"
NPROCS=$(nproc)

if [ $NPROCS -eq 1 ]
then
MAKEFLAGS=" -j1 "
else
MAKEFLAGS=" -j$((NPROCS-1))"
fi

EDITOR=nano
#export PS1 CARCH CHOST CFLAGS CXXFLAGS LDFLAGS LTOFLAGS MAKEFLAGS EDITOR
export PS1 CARCH CHOST MAKEFLAGS EDITOR
