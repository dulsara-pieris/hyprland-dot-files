#!/bin/bash

##########################
# Rofi Theme Generator
##########################

TEMPLATE="$HOME/.config/rofi/color.rasi"
OUTPUT="$HOME/.cache/wal/colors-rofi.rasi"
IMG_DIR="$HOME/.config/rofi/images"

mkdir -p "$HOME/.cache/wal"

# Make sure wal colors exist
if [[ ! -f ~/.cache/wal/colors.sh ]]; then
    echo "Error: Run 'wal -i <image>' first!"
    exit 1
fi

# Source wal colors
source ~/.cache/wal/colors.sh

# Pick a random image
if [[ -d "$IMG_DIR" ]]; then
    IMG_PATH=$(find "$IMG_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) 2>/dev/null | shuf -n1)
else
    IMG_PATH=""
fi

# Generate theme with wal colors
sed -e "s|%background%|${background}|g" \
    -e "s|%foreground%|${foreground}|g" \
    -e "s|%color1%|${color1}|g" \
    -e "s|%color4%|${color4}|g" \
    -e "s|%color6%|${color6}|g" \
    "$TEMPLATE" > "$OUTPUT"

# Insert background-image if we found one
if [[ -n "$IMG_PATH" && -f "$IMG_PATH" ]]; then
    sed -i '/background-image:/d' "$OUTPUT"
    sed -i "/^imagebox {/a\\    background-image: url(\"$IMG_PATH\", height);" "$OUTPUT"
fi

##########################
# Power Menu
##########################

# Options (Exit at top)
OPTIONS="Exit\nShutdown\nRestart\nSuspend\nLogout\nLock"

# Show menu with Rofi using the generated theme
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Power Options:" -theme "$OUTPUT")

# Run corresponding command
case "$CHOICE" in
    Exit)
        exit 0
        ;;
    Shutdown)
        notify-send -u critical "Shutdown"
        sleep 2s
        systemctl poweroff
        ;;
    Restart)
        notify-send -u critical "Restart"
        sleep 2s
        systemctl reboot
        ;;
    Suspend)
        notify-send -u critical "Suspend"
        sleep 2s
        systemctl suspend
        ;;
    Logout)
        notify-send -u critical "Loging out"
        sleep 2s
        hyprctl dispatch exit
        ;;
    Lock)
        notify-send -u critical "locking"
        sleep 2s
        hyprlock &
        ;;
    *)
        exit 0
        ;;
esac
