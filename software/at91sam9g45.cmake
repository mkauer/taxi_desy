set (CMAKE_SYSTEM_NAME Linux)

# get OE build directory from environment
SET(OE_ROOT $ENV{OE_ROOT})

SET(SYSFS $ENV{TOOLCHAIN_BASE}/taxi_sysfs)

set (CMAKE_MODULE_PATH ${OE_ROOT}/tmp-eglibc/sysroots/x86_64-linux/usr/share/cmake-2.8/Modules)
set (CMAKE_C_COMPILER ${OE_ROOT}/tmp-eglibc/sysroots/x86_64-linux/usr/bin/armv5te-oe-linux-gnueabi/arm-oe-linux-gnueabi-gcc)
set (CMAKE_CXX_COMPILER ${OE_ROOT}/tmp-eglibc/sysroots/x86_64-linux/usr/bin/armv5te-oe-linux-gnueabi/arm-oe-linux-gnueabi-g++)

set (CMAKE_SYSTEM_PROCESSOR AT91SAM)

add_definitions(-DARCH_AT91SAM)

set (CMAKE_FIND_ROOT_PATH ${SYSFS} )

set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
