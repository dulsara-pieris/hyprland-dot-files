#!/bin/bash

TEMPLATE="$HOME/.config/rofi/color.rasi"
OUTPUT="$HOME/.cache/wal/colors-rofi.rasi"
IMG_DIR="$HOME/.config/rofi/images"

# Create cache directory if it doesn't exist
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
    # Remove any existing background-image line
    sed -i '/background-image:/d' "$OUTPUT"

    # Insert background-image inside imagebox block with proper scaling
    sed -i "/^imagebox {/a\\    background-image: url(\"$IMG_PATH\", height);" "$OUTPUT"
fi

# Launch rofi
rofi -show drun -theme "$OUTPUT"
