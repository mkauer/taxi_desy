#!/bin/sh
#
# Init Script to load  the daq bus driver
#
#################################################################################

case "$1" in 
start)		insmod /opt/taxi/bin/daqdrv.ko ;;
stop)		rmmod daqdrv.ko ;;
restart)	rmmod daqdrv.ko
		insmod /opt/taxi/bin/daqdrv.ko ;;
esac
