#!/usr/bin/env bash

# ─────────────────────────────────────────────
# Rofi Wallpaper Selector for Hyprland + hyprpaper
# Works with restore-wallpaper.sh and current_wallpaper
# ─────────────────────────────────────────────

WALL_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.config/hypr/current_wallpaper"

# Check directory
[ -d "$WALL_DIR" ] || {
    notify-send "Wallpaper Error" "Wallpaper directory not found!"
    exit 1
}

# Get wallpaper list
WALLPAPER=$(ls "$WALL_DIR" | rofi -dmenu -i -p "Select Wallpaper")

# Exit if nothing selected
[ -z "$WALLPAPER" ] && exit 0

FULL_PATH="$WALL_DIR/$WALLPAPER"

# Ensure file exists
[ -f "$FULL_PATH" ] || exit 1

# Set wallpaper using hyprpaper
hyprctl hyprpaper preload "$FULL_PATH"
hyprctl hyprpaper wallpaper ",$FULL_PATH"

# Save to state file
echo "$FULL_PATH" > "$STATE_FILE"

notify-send "Wallpaper Changed" "$WALLPAPER"
