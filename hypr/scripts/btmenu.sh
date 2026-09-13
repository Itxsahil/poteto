#!/bin/bash

MAC_FILE="$HOME/.cache/bt_last_device"

log() {
    notify-send "Bluetooth" "$1"
}

ensure_bluetooth_ready() {
    bluetoothctl power on >/dev/null 2>&1
    sleep 1

    # Wait until controller is ready (max 5 seconds)
    for i in {1..5}; do
        if bluetoothctl show | grep -q "Powered: yes"; then
            return 0
        fi
        sleep 1
    done

    return 1
}

get_devices() {
    bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}'
}

connect_device() {
    mac="$1"

    ensure_bluetooth_ready || {
        log "Bluetooth not ready"
        exit 1
    }

    bluetoothctl <<EOF
agent on
default-agent
power on
connect $mac
EOF

    # retry once if fails
    sleep 2

    if ! bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        bluetoothctl connect "$mac"
    fi
}

pair_device() {
    mac="$1"

    ensure_bluetooth_ready || {
        log "Bluetooth not ready"
        exit 1
    }

    bluetoothctl <<EOF
agent on
default-agent
pair $mac
trust $mac
EOF
}

disconnect_device() {
    mac="$1"
    bluetoothctl disconnect "$mac"
}

main_menu="Scan & Connect
Paired Devices
Disconnect Device
Restart Bluetooth
Last Connected"

choice=$(echo -e "$main_menu" | rofi -dmenu -i -p "Bluetooth")

case "$choice" in

"Scan & Connect")
    ensure_bluetooth_ready || exit 1

    bluetoothctl scan on >/dev/null 2>&1
    sleep 3

    device=$(get_devices | rofi -dmenu -i -p "Select Device")
    mac=$(echo "$device" | awk '{print $1}')

    [ -z "$mac" ] && exit 0

    echo "$mac" > "$MAC_FILE"

    action=$(echo -e "Connect\nPair + Connect" | rofi -dmenu -i -p "Action")

    case "$action" in
        "Connect")
            connect_device "$mac"
            ;;
        "Pair + Connect")
            pair_device "$mac"
            connect_device "$mac"
            ;;
    esac
    ;;

"Paired Devices")
    device=$(bluetoothctl devices Paired | awk '{print $2 " " substr($0, index($0,$3))}' | rofi -dmenu -i -p "Paired")
    mac=$(echo "$device" | awk '{print $1}')
    [ -n "$mac" ] && connect_device "$mac"
    ;;

"Disconnect Device")
    device=$(bluetoothctl devices Connected | awk '{print $2 " " substr($0, index($0,$3))}' | rofi -dmenu -i -p "Connected")
    mac=$(echo "$device" | awk '{print $1}')
    [ -n "$mac" ] && disconnect_device "$mac"
    ;;

"Restart Bluetooth")
    sudo systemctl restart bluetooth
    sleep 2
    ensure_bluetooth_ready
    log "Bluetooth restarted"
    ;;

"Last Connected")
    if [ -f "$MAC_FILE" ]; then
        mac=$(cat "$MAC_FILE")
        connect_device "$mac"
    else
        log "No last device"
    fi
    ;;
esac