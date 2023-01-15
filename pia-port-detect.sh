#!/bin/sh

# GET ABSOLUTE PATH
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR
ABSOLUTE_PATH=$(pwd)

VPN_PORT="34595"
VPN_PORT=$(cat ${ABSOLUTE_PATH}/.vpn_port.temp)

echo "22" > ${ABSOLUTE_PATH}/.local_port.temp
LOCAL_PORT=$(cat ${ABSOLUTE_PATH}/.local_port.temp)

socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &
echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp


fifo_name="$ABSOLUTE_PATH/.vpn_port_pipe"

if ! [ -p "$fifo_name" ]; then
	mkfifo "$fifo_name"
fi

while true
do
    if read line; then
		PID=$(cat ${ABSOLUTE_PATH}/.socat_pid.temp)
		kill $PID
		echo "-1" > ${ABSOLUTE_PATH}/.socat_pid.temp

		VPN_PORT=$line
		LOCAL_PORT=$(cat ${ABSOLUTE_PATH}/.local_port.temp)
	
		socat tcp-listen:$VPN_PORT,reuseaddr,fork tcp:localhost:$LOCAL_PORT &
		echo "$!" > ${ABSOLUTE_PATH}/.socat_pid.temp
    fi
done <"$fifo_name"

exit 0
