#!/usr/bin/env bash

STATE="$HOME/.config/hypr/current_wallpaper"

[ -f "$STATE" ] || exit

WALL=$(cat "$STATE")

sleep 1

hyprctl hyprpaper preload "$WALL"
hyprctl hyprpaper wallpaper ",$WALL"
