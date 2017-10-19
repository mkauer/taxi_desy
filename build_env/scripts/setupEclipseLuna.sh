#!/bin/sh

BASE=`dirname \`readlink -f $0\``

source ${BASE}/tests.sh

FILE=${TOOLCHAIN_DOWNLOAD}/eclipse-cpp-luna-SR2-linux-gtk-x86_64.tar.gz
URL=http://ftp.halifax.rwth-aachen.de/eclipse//technology/epp/downloads/release/luna/SR2/eclipse-cpp-luna-SR2-linux-gtk-x86_64.tar.gz

#test for file
if [ ! -f ${FILE} ]
then
  wget $URL -O ${FILE}
fi

# extract
if [ -f ${FILE} ]
then

	mkdir -p $TOOLCHAIN_USER/workspace
	
	if [ -d $TOOLCHAIN_USER/eclipse ];
	then
		echo - IDE for current user is present in $TOOLCHAIN_USER/eclipse 
	else
		echo - creating IDE for current user in $TOOLCHAIN_USER/eclipse
		tar -C $TOOLCHAIN_BASE/software -xf $FILE
		mv $TOOLCHAIN_BASE/software/eclipse $TOOLCHAIN_USER/eclipse
		ln -s $TOOLCHAIN_USER/eclipse/eclipse $TOOLCHAIN_LOCAL/bin/hess_ide
	fi
else
	echo "Could not find source file ${FILE}. Maybe download was not ok?"
	exit -1
fi
