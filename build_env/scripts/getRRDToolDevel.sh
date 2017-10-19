#!/bin/bash

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/rrdtool-devel-1.4.7-1.slc6.wrl.x86_64.rpm
URL=http://packages.express.org/rrdtool/rrdtool-devel-1.4.7-1.slc6.wrl.x86_64.rpm

#test for file
if [ ! -f ${FILE} ]
then
  wget ${URL} -O ${FILE}
fi

# extract
if [ -f ${FILE} ]
then
	(cd ${TOOLCHAIN_LOCAL}; rpm2cpio ${FILE} | cpio -idmv)
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
