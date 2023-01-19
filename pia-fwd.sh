#!/bin/sh

ABSOLUTE_PATH="/home/$USER/Documents/Programs/pia-ip"

LOCAL_PORT=$1
echo "$LOCAL_PORT" > ${ABSOLUTE_PATH}/.local_port.temp

if [ -f "${ABSOLUTE_PATH}/.socat_pid.temp" ]; then
    PID=$(cat ${ABSOLUTE_PATH}/.socat_pid.temp)
    if ! [ "$PID" = "-1" ]; then
        kill $PID
    fi
fi
echo "-1" > ${ABSOLUTE_PATH}/.socat_pid.temp

VPN_PORT=$(/usr/local/bin/piactl get portforward)

if ! ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ]); then
    socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &> /dev/null &
    echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp
else
    >&2 echo "Failed! No valid VPN Port detected."
    exit 1
fi

exit 0