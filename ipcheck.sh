#!/bin/sh

# GET ABSOLUTE PATH
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR
ABSOLUTE_PATH=$(pwd)

function get_vpn_ip
{
	piactl get vpnip
}

function get_portforward
{
	piactl get portforward
}

# CHECK FOR PIA VPN IP
VPN_IP=$(get_vpn_ip)
MAX_CHECKS=20
CHECKS=0

while [ "$VPN_IP" = "Unknown" ]; do
	
    sleep 10;
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
PORTFORWARD=$(get_portforward)
MAX_CHECKS=3
CHECKS=0

while [ "$PORTFORWARD" = "Inactive" ]; do

    sleep 5;
	PORTFORWARD=$(get_portforward)

    CHECKS=$[ $CHECKS + 1 ]
    if [ $CHECKS -gt $MAX_CHECKS ]; then
        break
    fi
done

if [ "$PORTFORWARD" = "Inactive" ]; then
    exit 1
fi

echo "vpn ip: $VPN_IP, forwarded port: $PORTFORWARD"

# GET THE LOCAL IP

#source "${ABSOLUTE_PATH}/.env"

#IP_ADDRESS=$(ip a | grep ${INTERFACE_NAME} | grep inet)

#echo ${IP_ADDRESS} > ${ABSOLUTE_PATH}/ip_temp.txt

#IP_ADDRESS=$(cat ${ABSOLUTE_PATH}/ip_temp.txt)



# SEND THE LOCAL IP TO IFTTT ON startup ARG

if [[ "$1" == "startup" ]]; then
    curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"ip-info\": \"${IP_ADDRESS}\"}" https://maker.ifttt.com/trigger/${EVENT_NAME}/json/with/key/${IFTTT_KEY}

    echo ${IP_ADDRESS} > ${ABSOLUTE_PATH}/ip_state.txt

    exit 0
fi

# COMPARE THE NEW IP TO THE OLD IP ON NON-STARTUP FLAG

OLD_IP_ADDRESS=$(cat ${ABSOLUTE_PATH}/ip_state.txt)

if [[ "$OLD_IP_ADDRESS" == "$IP_ADDRESS" ]]; then
    echo "ip hasn't changed"
else
    curl -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"ip-info\": \"${IP_ADDRESS}\"}" https://maker.ifttt.com/trigger/${EVENT_NAME}/json/with/key/${IFTTT_KEY}
fi

echo ${IP_ADDRESS} > ${ABSOLUTE_PATH}/ip_state.txt

exit 0
