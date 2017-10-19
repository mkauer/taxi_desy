#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

NAME=monit
VERSION=5.12.2
FILE=${TOOLCHAIN_DOWNLOAD}/${NAME}-${VERSION}.tar.gz
BUILD_NAME=${NAME}-${VERSION}
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://mmonit.com/monit/dist/monit-${VERSION}.tar.gz

#test for file
if [ ! -f ${FILE} ]
then
  wget ${URL} -O ${FILE}
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
	
	(cd ${TOOLCHAIN_BUILD}; tar xzfv ${FILE})

	# compile
	(cd ${BUILD_DIR}; ./configure --prefix=${LOCAL_INSTALL} ; make -j 8 ; make install )
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
