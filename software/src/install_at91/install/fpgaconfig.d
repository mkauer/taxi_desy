#!/bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Init Script to configure the firmware image on the fpga
# Description:       .....
### END INIT INFO

source /opt/taxi/setupenv.sourceme

case "$1" in 
start)		/opt/taxi/bin/icescint_config -x 
			/opt/taxi/bin/icescint_drs4BaselineCalibrator -c /home/root/baseline_icetaxi02.csv
			;;
restart)	/opt/taxi/bin/icescint_config -x 
			/opt/taxi/bin/icescint_drs4BaselineCalibrator -c /home/root/baseline_icetaxi02.csv
			;;
stop)		;;
esac
