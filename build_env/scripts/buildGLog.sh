#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/glog-0.3.3.tar.gz
BUILD_NAME=glog-0.3.3
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL="https://google-glog.googlecode.com/files/glog-0.3.3.tar.gz"

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
	
	(cd ${TOOLCHAIN_BUILD}; tar xzf ${FILE})	

	# compile
	(cd ${BUILD_DIR}; ./configure --prefix=${LOCAL_INSTALL} ; make -j 8 ; make install )
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
