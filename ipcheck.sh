#!/bin/sh

# GET ABSOLUTE PATH
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR
ABSOLUTE_PATH=$(pwd)

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
	curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}
	echo "Running curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"local-ip\": \"${LOCAL_IP}\",\"vpn-ip\": \"${VPN_IP}\",\"vpn-port\": \"${VPN_PORT}\"}" https://maker.ifttt.com/trigger/${IFTTT_EVENT}/json/with/key/${IFTTT_KEY}"
}

# CHECK FOR PIA VPN IP
VPN_IP=$(get_vpn_ip)
MAX_CHECKS=10
CHECKS=0

while [ "$VPN_IP" = "Unknown" ]; do
	sleep 5;
	VPN_IP=$(get_vpn_ip)
	CHECKS=$[ $CHECKS + 1 ]
	if [ $CHECKS -gt $MAX_CHECKS ]; then
		break
	fi
done

if [ "$VPN_IP" = "Unknown" ]; then
	exit 1
fi


# CHECK FOR PIA FORWARDED PORT
VPN_PORT=$(get_portforward)
MAX_CHECKS=3
CHECKS=0

while [ "$VPN_PORT" = "Inactive" ]; do
	sleep 3;
	VPN_PORT=$(get_portforward)
	CHECKS=$[ $CHECKS + 1 ]
	if [ $CHECKS -gt $MAX_CHECKS ]; then
		break
	fi
done

# GET THE LOCAL IP
source "${ABSOLUTE_PATH}/.env"
LOCAL_INET=$(ip a | grep ${INTERFACE_NAME} | grep inet | xargs)
LOCAL_INET=($LOCAL_INET)
LOCAL_IP=${LOCAL_INET[1]}

# UPDATE ZONEEDIT DDNS (OPTIONAL)
# curl https://$ZONEEDIT_USERNAME:$ZONEEDIT_DYN_KEY@dynamic.zoneedit.com/auth/dynamic.html?host=$ZONEEDIT_HOSTNAME&myip=$VPN_IP

# CREATE NAMED PIPE TO TRANSFER PORT INFO THROUGH
if ! [ -p "${ABSOLUTE_PATH}/.vpn_port_pipe" ]; then
	mkfifo "${ABSOLUTE_PATH}/.vpn_port_pipe"
fi


# SEND THE LOCAL IP TO IFTTT ON startup ARG
if [[ "$1" == "startup" ]]; then
	ifttt_request
	echo ${LOCAL_IP} > ${ABSOLUTE_PATH}/.ip_local.temp
	echo ${VPN_IP} > ${ABSOLUTE_PATH}/.vpn_ip.temp
	echo ${VPN_PORT} > ${ABSOLUTE_PATH}/.vpn_port.temp
	echo ${VPN_PORT} > ${ABSOLUTE_PATH}/.vpn_port_pipe &
	exit 0
fi

# COMPARE THE NEW IP TO THE OLD IP ON NON-STARTUP FLAG
OLD_LOCAL_IP=$(cat ${ABSOLUTE_PATH}/.ip_local.temp)
OLD_VPN_IP=$(cat ${ABSOLUTE_PATH}/.vpn_ip.temp)
OLD_VPN_PORT=$(cat ${ABSOLUTE_PATH}/.vpn_port.temp)

if [[ "$OLD_VPN_PORT" != "$VPN_PORT" ]]; then
	echo ${VPN_PORT} > ${ABSOLUTE_PATH}/.vpn_port_pipe &
	ifttt_request
elif [[ "$OLD_LOCAL_IP" != "$LOCAL_IP" ]]; then
	ifttt_request
elif [[ "$OLD_VPN_IP" != "$VPN_IP" ]]; then
	ifttt_request
else
	echo "Nothing has changed"
	exit 0
fi

echo ${VPN_PORT} > ${ABSOLUTE_PATH}/.vpn_port.temp
echo ${LOCAL_IP} > ${ABSOLUTE_PATH}/.ip_local.temp
echo ${VPN_IP} > ${ABSOLUTE_PATH}/.vpn_ip.temp

exit 0
