#!/bin/sh

# GET ABSOLUTE PATH
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR
ABSOLUTE_PATH=$(pwd)

# CHECK IF THERE IS INTERNET CONNECTION
function check_online
{
	ON_NOW=$(netcat -z -w 5 1.1.1.1 53 && echo "1" || echo "0")
	if [ "$ON_NOW" = "1" ]; then
		echo "$ON_NOW"
	else
		ping -q -c 1 -W 3 archlinux.org &> /dev/null && echo "1" || echo "0"
	fi
}

# SEND IFTTT REQUEST
function ifttt_request
{
	curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"message\": \"${IFTTT_MESSAGE}\",\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}
	echo "Running curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}"
}

# CHECK FOR ONLINE STATUS
IS_ONLINE=$(check_online)
MAX_CHECKS=20
CHECKS=0

while [ "$IS_ONLINE" = "0" ]; do
	sleep 10;
	IS_ONLINE=$(check_online)
	CHECKS=$[ $CHECKS + 1 ]
	if [ $CHECKS -gt $MAX_CHECKS ]; then
		break
	fi
done


while true
do
    if read line; then

        if ! [ "$line" = "Attempting" ]; then

			ELAPSED=$((SECONDS-SENT_AT))

			if ([ $ELAPSED -gt 2 ] || [ $SECONDS -lt 5 ]); then

				source "${ABSOLUTE_PATH}/.env"
				LOCAL_INET=$(ip a | grep ${INTERFACE_NAME} | grep inet | xargs)
				LOCAL_INET=($LOCAL_INET)
				LOCAL_IP=${LOCAL_INET[1]}

				VPN_IP=$(/usr/local/bin/piactl get vpnip)
				VPN_PORT=$(/usr/local/bin/piactl get portforward)
            
			
				ifttt_request
				SENT_AT=$SECONDS

			fi
        fi
    fi
done < <((/usr/local/bin/piactl monitor vpnip) & (/usr/local/bin/piactl monitor portforward))

