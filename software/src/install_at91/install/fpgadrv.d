#!/bin/sh
#
# Init Script to load the fpga driver for loading firmware
#
#################################################################################

case "$1" in 
start)		insmod /opt/taxi/bin/fpgadrv.ko	;;
stop)		rmmod fpgadrv.ko ;;
restart)	rmmod fpgadrv.ko
		insmod /opt/taxi/bin/fpgadrv.ko	;;
esac
