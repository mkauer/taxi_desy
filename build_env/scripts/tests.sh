if [ -z $TOOLCHAIN_LOCAL ]; then
	echo "Environment Variable TOOLCHAIN_LOCAL not defined!"
	exit;
fi

if [ -z $TOOLCHAIN_BUILD ]; then
	echo "Environment Variable TOOLCHAIN_BUILD not defined!"
	exit;
fi

if [ -z $TOOLCHAIN_DOWNLOAD ]; then
	echo "Environment Variable TOOLCHAIN_DOWNLOAD not defined!"
	exit;
fi

if [ -z $TOOLCHAIN_DOWNLOAD ]; then
	echo "Environment Variable TOOLCHAIN_DOWNLOAD not defined!"
	exit;
fi

LOCAL_INSTALL=$TOOLCHAIN_LOCAL
LOCAL_LIB=${LOCAL_INSTALL}/lib
LOCAL_BIN=${LOCAL_INSTALL}/bin
LOCAL_INC=${LOCAL_INSTALL}/include

create_dir()
{
	# check if director exists
	if [ ! -d $1 ]; then
		# create directory
		mkdir $1
	fi
}
