#!/bin/sh

pipe=$1

if ! [ -p "$pipe" ]; then
	echo "$pipe does not exists"
fi

exit 0
socat tcp-listen:34595,reuseaddr,fork tcp:localhost:22 &

echo "$!" > .socat_pid.temp
