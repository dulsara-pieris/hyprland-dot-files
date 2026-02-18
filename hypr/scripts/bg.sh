#!/bin/bash
set -euo pipefail

#########################
# Configuration
#########################
WALL_DIR="$HOME/Pictures"
CACHE_DIR="$HOME/.cache/wallpaper-previews"
THUMB_SIZE="400x300"

#########################
# Check wallpaper directory
#########################
if [ ! -d "$WALL_DIR" ]; then
    echo "Wallpaper directory not found: $WALL_DIR"
    exit 1
fi

#########################
# Generate thumbnails
#########################
generate_thumbnails() {
    mkdir -p "$CACHE_DIR"

    find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read -r img; do
        hash=$(echo -n "$img" | md5sum | cut -d' ' -f1)
        thumb="$CACHE_DIR/${hash}.png"
        if [ ! -f "$thumb" ]; then
            convert "$img" -resize "$THUMB_SIZE^" -gravity center -extent "$THUMB_SIZE" "$thumb" 2>/dev/null || \
            magick "$img" -resize "$THUMB_SIZE^" -gravity center -extent "$THUMB_SIZE" "$thumb" 2>/dev/null || \
            cp "$img" "$thumb" 2>/dev/null
        fi
    done
}

#########################
# Apply wallpaper
#########################
apply_wallpaper() {
    local WALL="$1"

    if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
        echo "No wallpaper found"
        exit 1
    fi

    #########################
    # Set wallpaper with swww
    #########################
    if ! pgrep -x swww-daemon >/dev/null; then
        swww-daemon &
        sleep 0.5
    fi
    swww img "$WALL" --transition-type grow --transition-duration 3

    mkdir -p ~/.cache
    echo "$WALL" > ~/.cache/current_wallpaper
    sleep 1.5

    #########################
    # Apply pywal
    #########################
    if command -v wal >/dev/null; then
        wal -i "$WALL"
    fi

    #########################
    # Update EWW + GTK + Firefox
    #########################
    cp ~/.cache/wal/colors ~/.config/eww/dashboard/colors.scss 2>/dev/null || true
    eww --config ~/.config/eww/dashboard reload 2>/dev/null || true

    if command -v wal-gtk >/dev/null; then
        wal-gtk --apply
    fi

    if command -v pywalfox >/dev/null; then
        pywalfox update
    fi

    #########################
    # Update Hyprland borders
    #########################
    if command -v jq >/dev/null && command -v hyprctl >/dev/null && [ -f ~/.cache/wal/colors.json ]; then
        COLOR_ACTIVE=$(jq -r '.colors.color4' ~/.cache/wal/colors.json)
        COLOR_INACTIVE=$(jq -r '.colors.color0' ~/.cache/wal/colors.json)
        COLOR_FLOATING=$(jq -r '.colors.color3' ~/.cache/wal/colors.json)

        ACTIVE="0xff${COLOR_ACTIVE:1}"
        INACTIVE="0xff${COLOR_INACTIVE:1}"
        FLOATING="0xff${COLOR_FLOATING:1}"

        hyprctl windowrule -del name=pywal-borders >/dev/null 2>&1 || true
        hyprctl windowrule -add name=pywal-borders class=.* active_border="$ACTIVE" inactive_border="$INACTIVE" floating_border="$FLOATING" >/dev/null 2>&1 || true
    fi

    #########################
    # Generate Waybar colors file
    #########################
    if [ -f ~/.cache/wal/colors.json ]; then
        mkdir -p ~/.cache/wal
        jq -r '
            .colors as $c |
            "@define-color background \($c.color0);\n" +
            "@define-color foreground \($c.color7);\n" +
            "@define-color color1 \($c.color1);\n" +
            "@define-color color2 \($c.color2);\n" +
            "@define-color color3 \($c.color3);\n" +
            "@define-color color4 \($c.color4);\n" +
            "@define-color color5 \($c.color5);\n" +
            "@define-color color6 \($c.color6);\n" +
            "@define-color color8 \($c.color8);\n" +
            "@define-color color9 \($c.color9);\n" +
            "@define-color color10 \($c.color10);\n" +
            "@define-color color11 \($c.color11);\n" +
            "@define-color color12 \($c.color12);\n" +
            "@define-color color13 \($c.color13);\n" +
            "@define-color color14 \($c.color14);\n" +
            "@define-color color15 \($c.color15);\n"
        ' ~/.cache/wal/colors.json > ~/.cache/wal/colors-waybar.css
    fi

    #########################
    # Restart Waybar
    #########################
    pkill -x waybar >/dev/null 2>&1 || true
    sleep 1
    env DISPLAY="$DISPLAY" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css >/dev/null 2>&1 &

    echo "Wallpaper applied: $WALL"
    notify-send "Background changed"
}

#########################
# Main execution
#########################
main() {
    echo "Generating thumbnails..."
    generate_thumbnails

    # Pick a random wallpaper
    WALL=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

    if [ -z "${WALL:-}" ]; then
        echo "No wallpapers found in $WALL_DIR"
        exit 1
    fi

    apply_wallpaper "$WALL"
}

main
