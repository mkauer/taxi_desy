#!/bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Init Script to start srceen and the eventSender
# Description:       .....
### END INIT INFO

source /opt/taxi/setupenv.sourceme

case "$1" in 
start)		screen -dm /opt/taxi/bin/polarstern_eventSender -i -w -m 0 -a /data/ -d ;;
stop)		;;
esac
