#!/bin/bash

/usr/local/bin/piactl disconnect

if [ $# -eq 1 ]; then
    sleep $1
fi


/usr/local/bin/piactl connect