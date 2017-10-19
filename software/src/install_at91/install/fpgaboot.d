#!/bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Init Script to load the firmware image to the fpga
# Description:       .....
### END INIT INFO

source /opt/taxi/setupenv.sourceme

case "$1" in 
start)		/opt/taxi/bin/fpgainit -f /opt/firmware/defaultFirmware.bit ;;
stop)		;;
esac
