#!/bin/bash

MONITOR="eDP-1"

CHOICE=$(printf "Landscape\nPortrait Right\nPortrait Left\nUpside Down" | rofi -dmenu -p "Screen Orientation")

case "$CHOICE" in
    "Landscape")
        hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,0"
        ;;
    "Portrait Right")
        hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,1"
        ;;
    "Upside Down")
        hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,2"
        ;;
    "Portrait Left")
        hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,3"
        ;;
esac
