#!/bin/sh
#
# Init Script for the HESS1U upgrade
#
#################################################################################
echo_success() {
  echo -n "OK"
  return 0
}

echo_failure() {
  echo -n "FAILED"
  return 1
}

# Source hess1u 
[ -f /opt/hess1u/setupenv.sourceme ] && . /opt/hess1u/setupenv.sourceme

if [ -z "$HESS1U_ROOT" ] ;  then
  echo "HESS1U_ROOT is not set, please set it in /etc/default/service-name" >&2
  exit 1
fi

HESS1U_DRIVER=${HESS1U_ROOT}/bin/hessdrv.ko

[ -f $HESS1U_DRIVER ] || exit 0

RETVAL=0

case "$1" in 
start)  
    # initialize environment
    echo -n "Inserting hess1u driver: "
    /sbin/insmod /opt/hess1u/bin/hessdrv.ko
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then echo_success; else echo_failure; exit $RETVAL; fi
    echo "Starting hess1u init: "
    /opt/hess1u/bin/hess1u_init
    RETVAL=$?
    ;;
stop)
    echo -n "Removing hess1u driver: "
    /sbin/rmmod hessdrv.ko
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then echo_success; else echo_failure; exit $RETVAL; fi
    ;;
restart)
    $0 stop;
    $0 start;
    ;;
esac
exit $RETVAL
