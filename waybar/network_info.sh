#!/bin/bash
wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
eth=$(ip a | awk '/state UP/ && $2 !~ /lo/ {print $2}')
echo "Wi-Fi: ${wifi:-N/A} | Ethernet: ${eth:-N/A}"
