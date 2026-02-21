#!/usr/bin/env bash
# ~/.config/hypr/scripts/rofi-wifi.sh

ROFI_CMD="rofi -dmenu -theme ~/.config/rofi/network.rasi"
INTERFACE="wlp4s0"

# ── Helpers ───────────────────────────────────────────────────
wifi_enabled() {
    nmcli radio wifi | grep -q "enabled"
}

is_connected() {
    nmcli device status | grep "^$INTERFACE" | grep -q "connected"
}

current_ssid() {
    nmcli -t -f active,ssid dev wifi | grep "^yes" | cut -d: -f2
}

is_known() {
    nmcli connection show | grep -q "\"$1\""
}

# ── Toggle WiFi ───────────────────────────────────────────────
toggle_wifi() {
    if wifi_enabled; then
        nmcli radio wifi off
        notify-send "󰖪 WiFi" "WiFi turned off"
    else
        nmcli radio wifi on
        notify-send "󰤨 WiFi" "WiFi turned on"
    fi
}

# ── Forget a connection ───────────────────────────────────────
forget_network() {
    local ssid="$1"
    nmcli connection delete "$ssid" &&
        notify-send "󰤨 WiFi" "Forgot network: $ssid" ||
        notify-send "󰖪 WiFi" "Failed to forget: $ssid" -u critical
}

# ── Connect to network ────────────────────────────────────────
connect_network() {
    local ssid="$1"

    if is_known "$ssid"; then
        # Known network — just bring it up
        nmcli connection up "$ssid" &&
            notify-send "󰤨 WiFi" "Connected to $ssid" ||
            notify-send "󰖪 WiFi" "Failed to connect to $ssid" -u critical
    else
        # Unknown — prompt for password
        local pass
        pass=$(echo "" | $ROFI_CMD -p "󰌋  Password for '$ssid'")
        [ -z "$pass" ] && return
        nmcli device wifi connect "$ssid" password "$pass" ifname "$INTERFACE" &&
            notify-send "󰤨 WiFi" "Connected to $ssid" ||
            notify-send "󰖪 WiFi" "Wrong password or failed to connect" -u critical
    fi
}

# ── Network submenu ───────────────────────────────────────────
network_menu() {
    local ssid="$1"
    local connected="$2"   # "yes" or "no"
    local known="$3"        # "yes" or "no"
    local options=()

    if [ "$connected" = "yes" ]; then
        options+=("󰖪  Disconnect")
    else
        options+=("󰤨  Connect")
    fi

    [ "$known" = "yes" ] && options+=("󰌍  Forget Network")
    options+=("󰁍  Back")

    local chosen
    chosen=$(printf '%s\n' "${options[@]}" | $ROFI_CMD -p "󰤨  $ssid")
    [ -z "$chosen" ] && return

    case "$chosen" in
        "󰤨  Connect")
            connect_network "$ssid"
            ;;
        "󰖪  Disconnect")
            nmcli device disconnect "$INTERFACE" &&
                notify-send "󰖪 WiFi" "Disconnected from $ssid" ||
                notify-send "󰖪 WiFi" "Failed to disconnect" -u critical
            ;;
        "󰌍  Forget Network")
            forget_network "$ssid"
            ;;
        "󰁍  Back")
            main
            ;;
    esac
}

# ── Build network list ────────────────────────────────────────
get_networks() {
    local active_ssid
    active_ssid=$(current_ssid)

    # Rescan
    nmcli device wifi rescan ifname "$INTERFACE" 2>/dev/null
    sleep 1

    nmcli --terse -f IN-USE,SSID,BARS,SECURITY device wifi list ifname "$INTERFACE" 2>/dev/null \
        | grep -v "^--\|^$" \
        | awk -F: '!seen[$2]++' \
        | while IFS=: read -r inuse ssid bars security; do
            [ -z "$ssid" ] && continue

            # Signal icon based on bars
            case "$bars" in
                "▂▄▆█") icon="󰤨" ;;
                "▂▄▆_") icon="󰤥" ;;
                "▂▄__") icon="󰤢" ;;
                *)       icon="󰤟" ;;
            esac

            # Lock icon if secured
            lock=""
            echo "$security" | grep -qiv "none\|--" && lock=" 󰌋"

            # Mark active
            if [ "$ssid" = "$active_ssid" ]; then
                echo "  $icon $ssid$lock"
            else
                echo "  $icon $ssid$lock"
            fi
        done
}

# ── Main menu ─────────────────────────────────────────────────
main() {
    if wifi_enabled; then
        power_label="󰖪  Turn WiFi Off"
    else
        power_label="󰤨  Turn WiFi On"
    fi

    local menu="$power_label"

    if wifi_enabled; then
        menu+=$'\n'"󰤨  Rescan Networks"
        local nets
        nets=$(get_networks)
        if [ -n "$nets" ]; then
            menu+=$'\n'"────────────────────"
            menu+=$'\n'"$nets"
        fi
    fi

    local chosen
    chosen=$(echo "$menu" | grep -v '^$' | $ROFI_CMD -p "󰤨  WiFi")
    [ -z "$chosen" ] && exit 0

    case "$chosen" in
        "$power_label")
            toggle_wifi
            ;;
        "󰤨  Rescan Networks")
            notify-send "󰤨 WiFi" "Rescanning..."
            main
            ;;
        "────────────────────")
            exit 0
            ;;
        *)
            # Extract clean SSID — strip leading icon/spaces/active marker
            local ssid
            ssid=$(echo "$chosen" | sed 's/^[^a-zA-Z0-9_-]*//' | sed 's/ 󰌋$//' | xargs)

            local connected="no"
            local known="no"
            [ "$(current_ssid)" = "$ssid" ] && connected="yes"
            is_known "$ssid" && known="yes"

            network_menu "$ssid" "$connected" "$known"
            ;;
    esac
}

main

