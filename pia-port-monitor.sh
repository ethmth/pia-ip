#!/bin/sh

# GET ABSOLUTE PATH
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR
ABSOLUTE_PATH=$(pwd)

VPN_PORT=$(/usr/local/bin/piactl get portforward)
if ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ]); then
    VPN_PORT="34595" # Default VPN Port
fi

if ! [ -f "${ABSOLUTE_PATH}/.local_port.temp" ]; then
    echo "22" > ${ABSOLUTE_PATH}/.local_port.temp # Default Local Port
fi
LOCAL_PORT=$(cat ${ABSOLUTE_PATH}/.local_port.temp)

socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &
echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp

while true
do
    if read line; then

        VPN_PORT=$line
        if ! ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ]); then
            if [ -f "${ABSOLUTE_PATH}/.socat_pid.temp" ]; then
                PID=$(cat ${ABSOLUTE_PATH}/.socat_pid.temp)
                if ! [ "$PID" = "-1" ]; then
                    kill $PID
            fi
            echo "-1" > ${ABSOLUTE_PATH}/.socat_pid.temp


            if ! [ -f "${ABSOLUTE_PATH}/.local_port.temp" ]; then
                echo "22" > ${ABSOLUTE_PATH}/.local_port.temp # Default Local Port
            fi
            LOCAL_PORT=$(cat ${ABSOLUTE_PATH}/.local_port.temp)

            socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &
		    echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp
        fi
    fi
done < <(/usr/local/bin/piactl monitor portforward)

exit 0
