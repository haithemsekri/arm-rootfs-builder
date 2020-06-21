#!/bin/bash

g++ -std=gnu++03 -x c++  -E -dM -< /dev/null | grep __cplusplus
[ $? -eq 0 ] && L_CC_STD="-std=gnu03" && L_CXX_STD="-std=gnu++03"
g++ -std=gnu++11 -x c++  -E -dM -< /dev/null | grep __cplusplus
[ $? -eq 0 ] && L_CC_STD="-std=gnu11" && L_CXX_STD="-std=gnu++11"
g++ -std=gnu++14 -x c++  -E -dM -< /dev/null | grep __cplusplus
[ $? -eq 0 ] && L_CC_STD="-std=gnu11" && L_CXX_STD="-std=gnu++14"
g++ -std=gnu++17 -x c++  -E -dM -< /dev/null | grep __cplusplus
[ $? -eq 0 ] && L_CC_STD="-std=gnu11" && L_CXX_STD="-std=gnu++17"

[ -z "$L_CC_STD" ] && echo "L_CC_STD: not defined" && exit 1
[ -z "$L_CXX_STD" ] && echo "L_CXX_STD: not defined" && exit 1

LIB_NCURSES="$(find / -name libncurses.so)"
LIB_NCURSES5="$(find / -name libncurses.so.5)"

if [[ ! -z $LIB_NCURSES ]] && [[ ! -z $LIB_NCURSES5 ]]; then
   unlink $LIB_NCURSES
   ln -s $LIB_NCURSES5 $LIB_NCURSES
   symlinks -c "$(dirname $LIB_NCURSES)"
fi

cat << EOF > cross-build-env.sh
#!/bin/bash

[ -z "\$L_CROSS_COMPILE" ] && echo "L_CROSS_COMPILE: not defined" && exit 1
[ ! -f "\$L_CROSS_COMPILE"gcc ] && echo "L_CROSS_COMPILEgcc: file not found" && exit 1
[ -z "\$L_CROSS_PREFIX" ] && echo "L_CROSS_PREFIX: not defined" && exit 1
[ -z "\$L_CROSS_ARCH" ] && echo "L_CROSS_ARCH: not defined" && exit 1
[ -z "\$L_SYSROOT" ] && echo "L_SYSROOT: not defined" && exit 1
[ ! -d "\$L_SYSROOT" ] && echo "L_SYSROOT: dir not found" && exit 1

export L_CC="\${L_CROSS_COMPILE}gcc"
export L_CXX="\${L_CROSS_COMPILE}g++"
export L_LD="\${L_CROSS_COMPILE}ld"
export L_STRIP="\${L_CROSS_COMPILE}strip"
export L_RC="\${L_CROSS_COMPILE}rc"
export L_AR="\${L_CROSS_COMPILE}ar"
export L_AS="\${L_CROSS_COMPILE}as"
export L_PKG_CONFIG="/usr/bin/pkg-config"
export L_PKG_CONFIG_SYSROOT_DIR="\${L_SYSROOT}"

EOF

exec 1>> cross-build-env.sh

L_TAR_MACHINE="$(gcc -dumpmachine)"
echo "export L_TAR_MACHINE=\"$L_TAR_MACHINE\""
echo "export L_TAR_VERSION=\"$(gcc -dumpversion)\""
echo ""

echo "export L_PKG_CONFIG_LIBDIR=\$(cat <<EOF"
echo "$(find / -type d -name "pkgconfig" | awk '{ORS="" ;print "${L_SYSROOT}"$1":"}')"
echo "EOF"
echo ")"
echo ""

echo "export L_CFLAGS=\$(cat <<EOF"
echo "$L_CC_STD -nostdinc --sysroot=\${L_SYSROOT} -Wno-array-bounds -Wno-stringop-overflow -Wno-format-truncation \\"
echo "$(find / -name libc.so | xargs dirname | awk '{ORS="" ;print "-B${L_SYSROOT}"$1" "}')\\"
## https://gist.github.com/nickfox-taterli/35f84b51c1b4e373e1650b2750c4fedf
## http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dai0425/ch04s09s03.html
## https://gcc.gnu.org/onlinedocs/gcc-8.3.0/gcc/ARM-Options.html
## OXU4-Spec: echo "-DENABLE_NEON -mtune=cortex-a15.cortex-a7 -mfloat-abi=hard -mfpu=neon-vfpv4 -mcpu=cortex-a15.cortex-a7 -Ofast \\"
echo "$(echo | gcc -E -Wp,-v -o /dev/null - 2>&1 | grep "^ " | xargs realpath | awk '{ORS="" ;print "-isystem${L_SYSROOT}"$1" "}')"
echo "EOF"
echo ")"
echo ""

echo "export L_CXXFLAGS=\$(cat <<EOF"
echo "$L_CXX_STD -nostdinc++ --sysroot=\${L_SYSROOT} -Wno-array-bounds -Wno-stringop-overflow -Wno-format-truncation \\"
echo "$(find / -name libc.so | xargs dirname | awk '{ORS="" ;print "-B${L_SYSROOT}"$1" "}')\\"
[[ "$L_TAR_MACHINE" == *"-redhat-linux"* ]] && echo "$(find / -name libstdc++.so | xargs dirname | awk '{ORS="" ;print "-B${L_SYSROOT}"$1" "}')\\"
echo "$(echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1 | grep "^ " | xargs realpath | awk '{ORS="" ;print "-isystem${L_SYSROOT}"$1" "}')"
echo "EOF"
echo ")"
echo ""

echo "export L_LDFLAGS=\$(cat <<EOF"
echo "--sysroot=\${L_SYSROOT} \\"
echo "$(find / \( -name "libc.so" -o -name "libpthread-*.so" -o -name "libstdc++.so" \) | xargs dirname | awk '{ORS="" ;print "-Wl,-rpath-link=${L_SYSROOT}"$1" "}') "
echo "EOF"
echo ")"
echo ""

echo "export L_MAKE=\$(cat <<EOF"
echo "PKG_CONFIG=\"\${L_PKG_CONFIG}\" \\"
echo "PKG_CONFIG_LIBDIR=\"\${L_PKG_CONFIG_LIBDIR}\" \\"
echo "PKG_CONFIG_SYSROOT_DIR=\"\${L_PKG_CONFIG_SYSROOT_DIR}\" \\"
echo "LDFLAGS=\"\${L_LDFLAGS}\" \\"
echo "PYTHON=\"/usr/bin/python2\" \\"
echo "/usr/bin/make \\"
echo "CC=\"\${L_CC} \${L_CFLAGS}\" \\"
echo "CXX=\"\${L_CXX} \${L_CXXFLAGS}\" \\"
echo "LD=\"\${L_LD} \${L_LDFLAGS}\" \\"
echo "AR=\"\${L_AR}\" \\"
echo "STRIP=\"\${L_STRIP}\" \\"
echo "RC=\"\${L_RC}\" \\"
echo "AS=\"\${L_AS}\""
echo "EOF"
echo ")"
echo ""

echo "export L_CONFIGURE=\$(cat <<EOF"
echo "./configure \\"
echo "CC=\"\${L_CC} \${L_CFLAGS}\" \\"
echo "CXX=\"\${L_CXX} \${L_CXXFLAGS}\" \\"
echo "LD=\"\${L_LD} \${L_LDFLAGS}\" \\"
echo "LDFLAGS=\"\${L_LDFLAGS}\" \\"
echo "PYTHON=\"/usr/bin/python2\" \\"
echo "PKG_CONFIG=\"\${L_PKG_CONFIG}\" \\"
echo "PKG_CONFIG_LIBDIR=\"\${L_PKG_CONFIG_LIBDIR}\" \\"
echo "PKG_CONFIG_SYSROOT_DIR=\"\${L_PKG_CONFIG_SYSROOT_DIR}\""
echo "EOF"
echo ")"
echo ""
