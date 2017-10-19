cmake_minimum_required(VERSION 2.6)

include_directories(  )

FILE(GLOB_RECURSE SRCC *.c )
FILE(GLOB_RECURSE SRCH *.h )
FILE(GLOB_RECURSE INCH ${CMAKE_SOURCE_DIR}/taxi/driver/libdaqdrv/hal/*.h )

add_custom_target(
   daqdriver_all 
   COMMAND make -f ${CMAKE_CURRENT_SOURCE_DIR}/Makefile OE_ROOT=${OE_ROOT} INCLUDE_HAL=${CMAKE_SOURCE_DIR}/taxi/driver/libdaqdrv/hal MODULE_SOURCE=${CMAKE_CURRENT_SOURCE_DIR} 
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${SRCC} ${SRCH} ${INCH}
)

#set(ARCH arm)
#set(KERNEL_SOURCE ${OE_ROOT}/tmp-eglibc/work/stamp9g45-oe-linux-gnueabi/linux/3.0-r2/linux-3.0/)
#set(ARMCROSS ${OE_ROOT}/tmp-eglibc/sysroots/x86_64-linux/usr/bin/armv5te-oe-linux-gnueabi/arm-oe-linux-gnueabi-)

#set(EXTRA_CFLAGS -Wno-declaration-after-statement -O3 -g)
#set(EXTRA_CFLAGS ${EXTRA_CFLAGS} -DIS_KERNEL_SOURCE=1 )
#set(EXTRA_CFLAGS ${EXTRA_CFLAGS} -Wno-declaration-after-statement -O3 -g -DIS_KERNEL_SOURCE=1 -DARCH_AT91SAM -I . -I ${CMAKE_SOURCE_DIR}/taxi/driver/libdaqdrv/hal )

#message("KERNEL_SOURCE = ${KERNEL_SOURCE}")
#message("ARMCROSS = ${ARMCROSS}")

# this target does compiling without thehelp of the extra make file
#add_custom_target(
#   daqdriver_all2 
#   COMMAND export EXTRA_CFLAGS="${EXTRA_CFLAGS}" \; $(MAKE) -C ${KERNEL_SOURCE} ARCH=${ARCH} CROSS_COMPILE=${ARMCROSS} modules M=${CMAKE_CURRENT_SOURCE_DIR} 
#   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#   DEPENDS ${SRCC} ${SRCH} ${INCH}
#)


add_custom_target(
   daqdriver_clean clean
   COMMAND make -f ${CMAKE_CURRENT_SOURCE_DIR}/Makefile clean MODULE_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

#Message(${PROJECT_BINARY_DIR})
#Message(${CMAKE_CURRENT_BINARY_DIR})

install(FILES daqdrv.ko DESTINATION ${INSTALL_BIN})