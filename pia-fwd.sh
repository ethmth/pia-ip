#!/bin/sh

ABSOLUTE_PATH="/home/$USER/Documents/Programs/pia-ip"

LOCAL_PORT=$1
echo "$LOCAL_PORT" > ${ABSOLUTE_PATH}/.local_port.temp

PID=$(cat ${ABSOLUTE_PATH}/.socat_pid.temp)
kill $PID
echo "-1" > ${ABSOLUTE_PATH}/.socat_pid.temp

VPN_PORT=$(cat ${ABSOLUTE_PATH}/.vpn_port.temp)

socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &
echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp

exit 0
