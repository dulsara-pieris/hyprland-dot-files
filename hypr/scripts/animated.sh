#!/usr/bin/env bash

# Hyprland Wallpaper Manager
# Author: ChatGPT
# Requirements: swww, mpv, ffmpeg, imagemagick/convert, pywal, rofi, pywalfox

set -euo pipefail

# === CONFIGURATION ===
WALL_DIR="${1:-$HOME/Downloads}"        # Folder to scan for wallpapers
CACHE_DIR="$HOME/.cache/hypr-wall"      # Thumbnails cache
THUMB_SIZE=128                          # Thumbnail size
ROFI_CMD="rofi -dmenu -i -theme-str 'element-icon {size: ${THUMB_SIZE}px;}' -theme-str 'listview {columns: 6;}'"

# === DEPENDENCY CHECK ===
deps=(swww mpv ffmpeg convert wal rofi pywalfox)
missing=()
for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done

if (( ${#missing[@]} > 0 )); then
    echo "Warning: Missing dependencies: ${missing[*]}"
    echo "Some features may not work."
fi

mkdir -p "$CACHE_DIR"

# === FUNCTIONS ===

# Generate thumbnail for an image
thumb_image() {
    local src="$1"
    local dst="$2"
    if command -v convert &>/dev/null; then
        convert "$src" -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" "$dst"
    fi
}

# Generate thumbnail for a video (first frame)
thumb_video() {
    local src="$1"
    local dst="$2"
    if command -v ffmpeg &>/dev/null; then
        ffmpeg -y -i "$src" -vf "thumbnail,scale=${THUMB_SIZE}:${THUMB_SIZE}" -frames:v 1 "$dst" &>/dev/null
    fi
}

# Scan folder and generate thumbnails
generate_thumbs() {
    echo "Scanning $WALL_DIR..."
    FILES=()
    THUMBS=()
    while IFS= read -r -d '' file; do
        FILES+=("$file")
        base=$(basename "$file")
        thumb="$CACHE_DIR/$base.png"
        THUMBS+=("$thumb")
        # Generate if missing or regenerate forced
        if [[ ! -f "$thumb" || "$REGENERATE" == true ]]; then
            case "$file" in
                *.jpg|*.jpeg|*.png|*.webp) thumb_image "$file" "$thumb" ;;
                *.mp4) thumb_video "$file" "$thumb" ;;
            esac
        fi
    done < <(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.mp4" \) -print0)
}

# Apply image wallpaper
apply_image() {
    local img="$1"
    # swww set with smooth transition
    if command -v swww &>/dev/null; then
        swww img "$img" --transition-fps 60 --transition-type dissolve &
    fi
}

# Apply video wallpaper
apply_video() {
    local vid="$1"
    # Kill previous mpv wallpaper if running
    pkill -f "mpv.*--wid"
    if command -v mpv &>/dev/null; then
        # Launch mpv behind windows
        mpv --loop --no-audio --fullscreen --wid=$(hyprctl activewindow | awk '{print $2}') "$vid" &
    fi
}

# Generate pywal colors
apply_pywal() {
    local file="$1"
    if command -v wal &>/dev/null; then
        wal -i "$file" --saturate 0.8
        # Apply to GTK
        if [[ -f "$HOME/.cache/wal/colors.sh" ]]; then
            source "$HOME/.cache/wal/colors.sh"
            gsettings set org.gnome.desktop.interface gtk-theme "$WAL_THEME" 2>/dev/null || true
        fi
        # Apply to Waybar
        [[ -f "$HOME/.cache/wal/colors-waybar.css" ]] && pkill -USR1 waybar || true
        # Apply to Firefox via pywalfox
        command -v pywalfox &>/dev/null && pywalfox -f
        # Apply to Hyprland borders
        if [[ -d "$HOME/.config/hypr/colors" ]]; then
            border_file="$HOME/.config/hypr/colors/wal_colors.conf"
            echo "windowrule { class = '*' border_color = \"$color0\" }" > "$border_file"
            hyprctl reload
        fi
    fi
}

# Show Rofi selector
pick_wallpaper() {
    local choice
    local options=()
    for i in "${!FILES[@]}"; do
        options+=("${FILES[$i]}")  # Rofi shows full paths
    done

    choice=$(printf '%s\n' "${options[@]}" | $ROFI_CMD)
    echo "$choice"
}

# Random selection
random_wallpaper() {
    FILES=("$@")
    echo "${FILES[RANDOM % ${#FILES[@]}]}"
}

# === MAIN ===
REGENERATE=false
if [[ "${1:-}" == "--regen" ]]; then
    REGENERATE=true
fi

generate_thumbs

if [[ "${1:-}" == "--random" ]]; then
    SELECTED=$(random_wallpaper "${FILES[@]}")
else
    SELECTED=$(pick_wallpaper)
fi

if [[ -z "$SELECTED" ]]; then
    echo "No wallpaper selected."
    exit 0
fi

case "$SELECTED" in
    *.jpg|*.jpeg|*.png|*.webp)
        apply_image "$SELECTED"
        apply_pywal "$SELECTED"
        ;;
    *.mp4)
        apply_video "$SELECTED"
        apply_pywal "$SELECTED"
        ;;
    *)
        echo "Unsupported file type."
        exit 1
        ;;
esac

echo "Applied: $SELECTED"
