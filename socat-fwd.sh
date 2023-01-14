#!/bin/sh

LOCAL_PORT=$1
VPN_PORT=$2

socat tcp-listen:${VPN_PORT},reuseaddr,fork tcp:localhost:${LOCAL_PORT}
