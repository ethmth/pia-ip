#!/bin/sh


# Wait ~10 seconds. Have time of last send as variable. If current time > 60 secs difference, don't send

i=0
while true
do
    if read line; then

        if ! [ "$line" = "Attempting" ]; then

            ELAPSED=$((SECONDS-SENT_AT))
            if [ $ELAPSED -gt 2 ]; then
                echo "Diff CONNECT"
            fi
            echo "ELAPSED $ELAPSED"
            echo "$line"
            i=$((i+1))
            echo "$i"

            # echo "SECONDS $SECONDS"

            SENT_AT=$SECONDS
            echo "SENT AT $SENT_AT"

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