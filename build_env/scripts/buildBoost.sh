#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/boost_1_53_0.tar.gz
BUILD_NAME=boost_1_53_0
BUILD_DIR=${TOOLCHAIN_BUILD}/${BUILD_NAME}
URL=http://downloads.sourceforge.net/project/boost/boost/1.53.0/boost_1_53_0.tar.gz?use_mirror=dfn

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
	(cd ${BUILD_DIR}; ./bootstrap.sh --with-libraries=atomic,chrono,date_time,filesystem,graph,iostreams,program_options,regex,random,signals,system,test,thread,timer --prefix=${LOCAL_INSTALL}/usr/boost_1_53_0 --libdir=${LOCAL_LIB} --includedir=${LOCAL_INC} --exec-prefix=${LOCAL_BIN}; ./bjam threading=multi ; ./bjam install )

	# write pkgconfig
	BOOSTLIBS=$(ls ${LOCAL_LIB}/libboost*.so | grep -o libboost_.* | sed -e "s/.so//" -e "s/lib/-l/" | tr '\n' ' ')
    mkdir -p ${LOCAL_LIB}/pkgconfig
	cat > ${LOCAL_LIB}/pkgconfig/boost.pc << EOF
	prefix=${TOOLCHAIN_LOCAL}
	exec_prefix=\${prefix}
	libdir=\${exec_prefix}/lib
	includedir=\${prefix}/include

	Name: boost
	Description: BOOST c++ libraries
	Version: 1.53.0
	Libs: -L\${libdir} ${BOOSTLIBS}
Cflags: -I\${includedir}
EOF
	
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
