#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/astro_root-5.0.tar.gz
BUILD_NAME=astro_root-5.0
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://www.isdc.unige.ch/astroroot/astro_root-5.0.tar.gz

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
	
	(cd ${TOOLCHAIN_BUILD}; mkdir ${BUILD_DIR}; tar xzfv ${FILE} -C ${BUILD_DIR})

	# compile
	(cd ${BUILD_DIR}; 
	export ISDC_ENV=${BUILD_DIR}
	mkdir ${ISDC_ENV}/pfiles
	export CC=gcc
	export CXX=g++
	export CFLAGS=-fPIC
	export CXXFLAGS=-fPIC
	export PFILES=".:${ISDC_ENV}/pfiles:${PFILES}"
	export PATH=${ISDC_ENV}/bin:${PATH}
	export LD_LIBRARY_PATH=${ISDC_ENV}/lib:${LD_LIBRARY_PATH}
	makefiles/ac_stuff/configure
	make
	make install
	)
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
