cmake_minimum_required(VERSION 2.6)

enable_testing()

project(taxi)

include (${CMAKE_SOURCE_DIR}/common.cmake) 

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# set no install prefix in order to have a easier scripted install
else()
# this is set by the createBuild.sh script 
#	set(CMAKE_INSTALL_PREFIX /opt/taxi)
endif()

add_subdirectory( src )

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	SET(CPACK_GENERATOR "TGZ")
else()
	SET(CPACK_GENERATOR "TGZ;RPM")
endif()
	
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "taxi project software")
SET(CPACK_PACKAGE_VENDOR "DESY")

#SET(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ReadMe.txt")
#SET(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/Copyright.txt")
SET(CPACK_PACKAGE_VERSION_MAJOR "0")
SET(CPACK_PACKAGE_VERSION_MINOR "1")
SET(CPACK_PACKAGE_VERSION_PATCH "1")
#SET(CPACK_PACKAGE_INSTALL_DIRECTORY "CMake ${CMake_VERSION_MAJOR}.${CMake_VERSION_MINOR}")

SET(CPACK_SOURCE_STRIP_FILES "")

if (CMAKE_SYSTEM_PROCESSOR STREQUAL AT91SAM)
	# set no install prefix in order to have a easier scripted install
	set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY 0)	
else()
	set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/taxi")
endif()

#set(CPACK_RPM_PACKAGE_REQUIRES "monit >= 5")

INCLUDE(CPack)
