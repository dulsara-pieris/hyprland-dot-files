#!/bin/bash

# Check if the dashboard Waybar is running
if pgrep -f "waybar.*dashboard.json" >/dev/null; then
    pkill -f "waybar.*dashboard.json"
else
    waybar -c ~/.config/waybar/dashboard.json &
fi
