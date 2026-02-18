#!/bin/bash
# One-key scratchpad music launcher + toggle
SCRATCHPAD_CLASS="scratchpad_music"

# Launch kitty + ncmpcpp in scratchpad if not running
if hyprctl clients | grep -iq "$SCRATCHPAD_CLASS"; then
    # Toggle visibility
    hyprctl dispatch togglespecialworkspace "$SCRATCHPAD_CLASS"
else
    # Launch scratchpad
    kitty --class "$SCRATCHPAD_CLASS" -e termusic &
    sleep 0.5
    hyprctl dispatch togglespecialworkspace "$SCRATCHPAD_CLASS"
fi
