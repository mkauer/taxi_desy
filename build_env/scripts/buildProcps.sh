#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/procps-3.2.8
BUILD_NAME=procps-3.2.8
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://procps.sourceforge.net/procps-3.2.8.tar.gz

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
	(cd ${BUILD_DIR}; make -j 8 ; make DESTDIR=${LOCAL_INSTALL} install="install -D" ldconfig=echo install )

    # link lib
    (cd ${LOCAL_INSTALL}/lib64 ; ln -sf libproc-3.2.8.so libproc.so )

    # copy headers
    (mkdir -p $LOCAL_INSTALL/include/proc; cp $BUILD_DIR/proc/*.h $LOCAL_INSTALL/include/proc/ )
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
