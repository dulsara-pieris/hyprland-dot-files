#!/bin/bash
cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)"%"}')
ram=$(free -h | awk '/^Mem/ {print $3 "/" $2}')
disk=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
echo "CPU: $cpu | RAM: $ram | Disk: $disk"
