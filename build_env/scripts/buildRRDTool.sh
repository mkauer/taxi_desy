#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/rrdtool-1.5.4.tar.gz
BUILD_NAME=rrdtool-1.5.4
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.5.4.tar.gz

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
	(cd ${BUILD_DIR}; ./configure --prefix=${TOOLCHAIN_LOCAL} PY_PREFIX=$TOOLCHAIN_LOCAL/usr ; make -j 8 ; make install )
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
