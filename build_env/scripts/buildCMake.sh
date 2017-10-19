#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

BUILD_NAME=cmake-2.8.10.2
FILE=${TOOLCHAIN_DOWNLOAD}/${BUILD_NAME}.tar.gz
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}

#test for file
if [ ! -f ${FILE} ]
then
  wget http://www.cmake.org/files/v2.8/${BUILD_NAME}.tar.gz -O ${FILE}
fi

# extract
if [ -f ${FILE} ]
then
	if [ "$1" != "forceBuild" ] 
	then
		if [ -d ${BUILD_DIR} ] 
		then
			echo "Build Directory ${BUILD_DIR} already exists, build skipped" 
			exit 0
		fi
	fi
	(cd ${TOOLCHAIN_BUILD}; tar xzf ${FILE})

	# compile
	(cd ${BUILD_DIR}; ./configure --prefix=${LOCAL_INSTALL} ; make -j 3 ; make install )
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
