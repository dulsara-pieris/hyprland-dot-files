#!/bin/bash
CHECKUPDATES=/usr/bin/checkupdates

ping -c 1 archlinux.org &>/dev/null
if [ $? -ne 0 ]; then
    echo "offline"
    exit 0
fi

UPDATES=$($CHECKUPDATES 2>/dev/null | wc -l)

if [ "$UPDATES" -eq 0 ]; then
    echo "0 updates"
else
    echo " $UPDATES updates"
fi
