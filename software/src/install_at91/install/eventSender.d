#!/bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Init Script to start the eventSender
# Description:       .....
### END INIT INFO

source /opt/taxi/setupenv.sourceme

case "$1" in 
start)		if pgrep -x "eventSender" > /dev/null
			then
				echo "eventSender already running"
			else
				/opt/taxi/bin/eventSender &
			fi 
			;;
stop)		killall -9 eventSender
			;;
restart)	killall -9 eventSender
			/opt/taxi/bin/eventSender &
esac
