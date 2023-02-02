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

# GET THE VPN CONNECTION STATUS AND PORT FROM PIACTL
function get_vpn_ip
{
	/usr/local/bin/piactl get vpnip
}

function get_portforward
{
	/usr/local/bin/piactl get portforward
}


# SEND IFTTT REQUEST
function ifttt_request
{
	echo "Running curl -o /dev/null -X POST -H \"Content-Type: application/json\" -d \"{\"message\": \"${IFTTT_MESSAGE}\",\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}\" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}"
	curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"message\": \"${IFTTT_MESSAGE}\",\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}
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

# CHECK FOR PIA VPN IP
VPN_IP=$(get_vpn_ip)
MAX_CHECKS=2
CHECKS=0

while ([ "$VPN_IP" = "Unknown" ] || [ "$VPN_IP" = "Attempting" ]); do
	sleep 5;
	VPN_IP=$(get_vpn_ip)
	CHECKS=$[ $CHECKS + 1 ]
	if [ $CHECKS -gt $MAX_CHECKS ]; then
		break
	fi
done

# CHECK FOR PIA FORWARDED PORT
VPN_PORT=$(get_portforward)
MAX_CHECKS=3
CHECKS=0

while ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ] || [ "$VPN_PORT" = "Failed" ] || [ "$VPN_PORT" = "Unavailable" ]); do
	sleep 1;
	VPN_PORT=$(get_portforward)
	CHECKS=$[ $CHECKS + 1 ]
	if [ $CHECKS -gt $MAX_CHECKS ]; then
		break
	fi
done

source "${ABSOLUTE_PATH}/.env"
LOCAL_INET=$(ip a | grep ${INTERFACE_NAME} | grep inet | xargs)
LOCAL_INET=($LOCAL_INET)
LOCAL_IP=${LOCAL_INET[1]}

VPN_IP=$(/usr/local/bin/piactl get vpnip)
VPN_PORT=$(/usr/local/bin/piactl get portforward)

PAYLOAD="{\"message\": \"${IFTTT_MESSAGE}\",\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}"
ifttt_request
echo "$PAYLOAD" > ${ABSOLUTE_PATH}/.sent_payload.temp

exit 0