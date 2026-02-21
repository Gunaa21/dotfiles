#!/usr/bin/env bash
# Monitors battery and sends dunst notifications at 20% and 10%

BATTERY="BAT0"  # change to BAT0 if needed — check below
NOTIFIED_20=false
NOTIFIED_10=false

# Check which battery you have
# ls /sys/class/power_supply/

while true; do
    CAPACITY=$(cat /sys/class/power_supply/$BATTERY/capacity 2>/dev/null)
    STATUS=$(cat /sys/class/power_supply/$BATTERY/status 2>/dev/null)

    # Reset flags when charging
    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        NOTIFIED_20=false
        NOTIFIED_10=false
        sleep 60
        continue
    fi

    # 20% warning
    if [ "$CAPACITY" -le 20 ] && [ "$NOTIFIED_20" = false ]; then
        notify-send -a "Battery" -u normal \
            "󰁻 Battery Low" \
            "Battery at ${CAPACITY}%. Please plug in." \
            -h string:synchronous:battery
        NOTIFIED_20=true
    fi

    # 10% critical
    if [ "$CAPACITY" -le 10 ] && [ "$NOTIFIED_10" = false ]; then
        notify-send -a "Battery Critical" -u critical \
            "󰁺 Battery Critical" \
            "Battery at ${CAPACITY}%! Plug in immediately." \
            -h string:synchronous:battery
        NOTIFIED_10=true
    fi

    sleep 60
done
