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

# i=0
while true
do
    if read line; then

        if ! [ "$line" = "Attempting" ]; then
            # echo "$line"
            # i=$((i+1))
            # echo "$i"

			ELAPSED=$((SECONDS-SENT_AT))

			if ([ $ELAPSED -gt 2 ] || [ $SECONDS -lt 5 ]); then
                # echo "Diff CONNECT"

				# GET THE LOCAL IP
				source "${ABSOLUTE_PATH}/.env"
				LOCAL_INET=$(ip a | grep ${INTERFACE_NAME} | grep inet | xargs)
				LOCAL_INET=($LOCAL_INET)
				LOCAL_IP=${LOCAL_INET[1]}
            fi




			SENT_AT=$SECONDS

            # echo "ELAPSED $ELAPSED"
            # echo "$line"
            # i=$((i+1))
            # echo "$i"

            # echo "SECONDS $SECONDS"

            # SENT_AT=$SECONDS

        fi

        # VPN_PORT=$line
		# echo "$VPN_PORT"
        # if ! ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ]); then
            # echo "That's valid silly"
        # fi
    fi
# done < <(cat $(/usr/local/bin/piactl monitor portforward))
# done < <(cat <(/usr/local/bin/piactl monitor vpnip) <(/usr/local/bin/piactl monitor portforward))
done < <((/usr/local/bin/piactl monitor vpnip) & (/usr/local/bin/piactl monitor portforward))

