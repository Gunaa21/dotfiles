#!/usr/bin/env bash
# ~/.config/hypr/scripts/rofi-bluetooth.sh

ROFI_CMD="rofi -dmenu -theme ~/.config/rofi/network.rasi"

# ── Only this approach works non-interactively on this system ─
bt() {
    echo -e "$1\nquit" | bluetoothctl 2>/dev/null
}

bt_power() {
    bt "show" | grep -q "Powered: yes"
}

device_connected() {
    bt "info $1" | grep -q "Connected: yes"
}

device_trusted() {
    bt "info $1" | grep -q "Trusted: yes"
}

# ── Get all devices, parse from pipe output ───────────────────
get_devices() {
    bt "devices" | grep "^Device" | while read -r _ mac name; do
        echo "$mac $name"
    done
}

# ── Toggle power ──────────────────────────────────────────────
toggle_power() {
    if bt_power; then
        bt "power off"
        notify-send "󰂲 Bluetooth" "Bluetooth turned off"
    else
        bt "power on"
        notify-send "󰂯 Bluetooth" "Bluetooth turned on"
    fi
}

# ── Scan for new devices ──────────────────────────────────────
scan_devices() {
    notify-send "󰂯 Bluetooth" "Scanning for 10 seconds..."
    # Scan needs to stay open, use a subshell with timeout
    echo -e "scan on" | bluetoothctl &
    sleep 10
    bt "scan off"
    kill %1 2>/dev/null
    main
}

# ── Device submenu ────────────────────────────────────────────
device_menu() {
    local mac="$1"
    local name="$2"
    local options=()

    if device_connected "$mac"; then
        options+=("󰂲  Disconnect")
    else
        options+=("󰂱  Connect")
    fi

    device_trusted "$mac" \
        && options+=("  Untrust") \
        || options+=("  Trust")

    options+=("󰌍  Remove & Unpair")
    options+=("󰁍  Back")

    local chosen
    chosen=$(printf '%s\n' "${options[@]}" | $ROFI_CMD -p "󰂯  $name")
    [ -z "$chosen" ] && return

    case "$chosen" in
        "󰂱  Connect")
            bt "connect $mac"
            sleep 2
            device_connected "$mac" \
                && notify-send "󰂱 Bluetooth" "Connected to $name" \
                || notify-send "󰖪 Bluetooth" "Failed to connect to $name" -u critical
            ;;
        "󰂲  Disconnect")
            bt "disconnect $mac"
            notify-send "󰂲 Bluetooth" "Disconnected from $name"
            ;;
        "  Trust")
            bt "trust $mac"
            notify-send "󰂯 Bluetooth" "Trusted $name"
            ;;
        "  Untrust")
            bt "untrust $mac"
            notify-send "󰂯 Bluetooth" "Untrusted $name"
            ;;
        "󰌍  Remove & Unpair")
            bt "remove $mac"
            notify-send "󰂯 Bluetooth" "Removed $name"
            ;;
        "󰁍  Back")
            main
            ;;
    esac
}

# ── Main menu ─────────────────────────────────────────────────
main() {
    if bt_power; then
        power_label="󰂲  Turn Bluetooth Off"
    else
        power_label="󰂯  Turn Bluetooth On"
    fi

    # Build device entries — grep for "^Device" to skip all the 
    # [NEW] Media / Endpoint / Agent noise from pipe output
    local entries=""
    while read -r mac name; do
        [ -z "$mac" ] && continue
        if device_connected "$mac"; then
            entries+="󰂱  $name  [$mac]"$'\n'
        else
            entries+="󰂯  $name  [$mac]"$'\n'
        fi
    done < <(get_devices)

    # Assemble menu
    local menu="$power_label"
    if bt_power; then
        menu+=$'\n'"󰂱  Scan for New Devices"
        if [ -n "$entries" ]; then
            menu+=$'\n'"────────────────────"
            menu+=$'\n'"$entries"
        fi
    fi

    local chosen
    chosen=$(echo "$menu" | grep -v '^$' | $ROFI_CMD -p "󰂯  Bluetooth")
    [ -z "$chosen" ] && exit 0

    case "$chosen" in
        "$power_label")
            toggle_power
            ;;
        "󰂱  Scan for New Devices")
            scan_devices
            ;;
        "────────────────────")
            exit 0
            ;;
        *)
            # MAC is inside [ ] at end of line
            local mac name
            mac=$(echo "$chosen" | grep -oP '(?<=\[)[A-F0-9:]+(?=\])')
            name=$(echo "$chosen" | sed 's/^[^ ]* //' | sed 's/  \[.*//' | xargs)
            [ -n "$mac" ] && device_menu "$mac" "$name"
            ;;
    esac
}

main

