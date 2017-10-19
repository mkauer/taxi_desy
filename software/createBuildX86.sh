#!/bin/sh

# Helper Script to creates the initial cmake projects build directories
#
# the scripts creates the build directories for debug and release configurations within the existing directory 
# the script assumes that it placed inside of the cmake source directory
# 

DUM=`readlink -f $0`
CMAKE_SOURCE_PATH=`dirname $DUM`
NAME=`basename $CMAKE_SOURCE_PATH`

echo $CMAKE_SOURCE_PATH
echo $NAME

# 1. argument = BuildDir Prefix
# 2. argument = CMAKE Build Type
# 3. argument = Makefile Generator
# 4. extra arguments for cmake
cmake_build_dir() {
	ORGINAL_DIR=`pwd`
	BUILDDIR=${NAME}_$1_$2
	
	if [ ! -d ${BUILDDIR} ]; then
		mkdir ${BUILDDIR}
	fi
	cd ${BUILDDIR}
	
	cmake ${CMAKE_SOURCE_PATH} -DCMAKE_BUILD_TYPE:STRING=$2 $4 $5 -G "$3"
	
	cd $ORGINAL_DIR 
}

cmake_build_dir x86 Debug "Eclipse CDT4 - Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/opt/hess1u
cmake_build_dir x86 Release "Eclipse CDT4 - Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/opt/hess1u
