#!/bin/bash

echo "Running sysroot basic env generation ..."

echo "DISTRO_CC_ARCH=\"$(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep -E "^*/usr/lib/gcc/*.*include$" | cut -d"/" -f5)\""
echo "DISTRO_CC_VERSION=\"$(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep -E "^*/usr/lib/gcc/*.*include$" | cut -d"/" -f6)\""

exec 1> sysroot_basic_env.sh
echo "#!/bin/bash"
echo ""
echo "DISTRO_CC_ARCH=\"$(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep -E "^*/usr/lib/gcc/*.*include$" | cut -d"/" -f5)\""
echo "DISTRO_CC_VERSION=\"$(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep -E "^*/usr/lib/gcc/*.*include$" | cut -d"/" -f6)\""
echo ""
echo "SYSROOT_INC_CFLAGS=\$(cat <<EOF"
echo -n $(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep "^ " | sed "s|^ /| -isystem\${SYSROOT_PATH}/|")
echo -n " "
echo $(bash -c "echo | g++ -x c++ -E -Wp,-v -o /dev/null - 2>&1" | grep "^ " | sed "s|^ /| -I\${SYSROOT_PATH}/|")
echo "EOF"
echo ")"
