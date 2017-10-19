#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/thrift-0.9.1.tar.gz
BUILD_NAME=thrift-0.9.1
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://archive.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz

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
	(cd ${BUILD_DIR}; ./configure --prefix=${LOCAL_INSTALL} PY_PREFIX=$LOCAL_INSTALL/usr --with-boost=$LOCAL_INSTALL --with-libevent --without-qt4 --without-csharp --without-c_glib --without-java --without-erlang --without-perl --without-php --without-php_extension --without-ruby --without-haskell --without-go --without-d --without-tests ; make -j 8 ; make install )
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
