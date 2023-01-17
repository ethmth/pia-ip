#!/bin/sh


while true
do
    if read line; then
        VPN_PORT=$line
		echo "$VPN_PORT"
        if ! ([ "$VPN_PORT" = "Inactive" ] || [ "$VPN_PORT" = "Attempting" ]); then
            echo "That's valid silly"
        fi
    fi
done < <(/usr/local/bin/piactl monitor portforward)