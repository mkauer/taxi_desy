#!/bin/sh

# make shell script stop if user hits ctrl-c
trap exit int

# general installation for all systems
# ====================================

export TAXI_ROOT=/opt/taxi

# create profile in home directory 
test -e ~/.profile && rm ~/.profile
cp ${TAXI_ROOT}/install/profile ~/.profile

# create opkg desy feed
cp ${TAXI_ROOT}/install/desy-feed.conf /etc/opkg/

# create lighttpd conf
#cp ${TAXI_ROOT}/install/lighttpd.conf /etc/
#ln -s ${TAXI_ROOT}/bin/lighttpd.conf /etc/lighttpd-taxi.conf

disableService()
{
	if [ -f /etc/init.d/$1 ] ; then 
		update-rc.d -f $1 remove
		rm /etc/init.d/$1
	fi
}

enableService()
{
	#remove old init rc scripts
    disableService $1

	#copy init script 
    cp ${TAXI_ROOT}/install/$1 /etc/init.d/$1
	chmod 755 /etc/init.d/$1
    

	#install init rc script
    update-rc.d $1 defaults $2
}

#opkg update
#opkg install lighttpd lighttpd-module-fastcgi

# do global system service installation
enableService smcdrv.d 40
enableService fpgadrv.d 41
enableService fpgaboot.d 60
enableService daqdrv.d 61
enableService fpgaconfig.d 62
enableService eventSender.d 90
#enableService screen.d 90
