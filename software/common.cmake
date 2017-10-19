###############################################################################
# 
# Common CMAKE definitions to help compile all HESS1U software 
# 
# Changes:
# 2014-02-07	MP	added support for external libraries 
# 2015-05-14	GG	general clean-up, now thrift is external for both archs
#
###############################################################################

if ( CMAKE_COMPILER_IS_GNUCC )
	# fix some nagging compiler warning
	add_definitions(-Wno-packed-bitfield-compat)
endif ()

set(TOOLCHAIN_BASE $ENV{TOOLCHAIN_BASE})
set(TOOLCHAIN_LOCAL $ENV{TOOLCHAIN_LOCAL})
set(TOOLCHAIN_CROSS $ENV{TOOLCHAIN_CROSS})

# Predefined permissions sets

set(PERM755 OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
set(PERM600 OWNER_READ OWNER_WRITE )

include(cmake/buildhelp.cmake)

############################# LIBRARY Registration ############################
#
# Each common (shipped) library to be used must be registered with its include 
# library paths
#
###############################################################################

register_library( src/driver/libsmcdrv smcdrv ) 
register_library( src/driver/libdaqdrv daqdrv ) 
register_library( src/driver/libfpgadrv fpgadrv )
 
register_library( src/libfastcfgipp fastcgipp ) 
register_library( src/libtaxihal taxihal ) 
register_library( src/libcommon common ) 

register_library( src/icescint/common icescint_common ) 

############################# LIBRARY Setup ############################
#
# Setup external libraries 
#
###############################################################################

# Architecture specific setups

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	message("INFO: Building for arm architecture '${CMAKE_SYSTEM_PROCESSOR}'")

	if (${TOOLCHAIN_CROSS})
		message("WARNING! Environment variable $TOOLCHAIN_CROSS is not defined!")
	else()
		message("INFO: Using cross tool/lib path \"${TOOLCHAIN_CROSS}\" ")
	endif()	
		    
else()
	message("INFO: Building for x86 architecture '${CMAKE_SYSTEM_PROCESSOR}'")
		
	if (${TOOLCHAIN_LOCAL})
		message("WARNING! Environment variable $TOOLCHAIN_LOCAL is not defined!")
	else()
		message("INFO: Using local tool/lib path \"${TOOLCHAIN_LOCAL}\" ")
	endif()	
	
	set (CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_LOCAL} )
		
endif()

# External libraries

include(cmake/boost.cmake)
include(cmake/glog.cmake)
include(cmake/zmq.cmake)
include(cmake/lib_fastcgi.cmake)

#include(cmake/procps.cmake)
#include(cmake/pthread.cmake)
#include(cmake/protobuf.cmake)
include(cmake/thrift.cmake)
#include(cmake/ncurses.cmake)
#include(cmake/poco.cmake)
include(cmake/poco.cmake)


include(cmake/lib_root.cmake)
