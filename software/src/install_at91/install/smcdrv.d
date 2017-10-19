#!/bin/sh
#
# Init Script to load the daq bus driver used for IRQ based readout with DMA
#
#################################################################################

case "$1" in 
start)		insmod /opt/taxi/bin/smcdrv.ko ;;
stop)		rmmod smcdrv.ko ;;
esac
