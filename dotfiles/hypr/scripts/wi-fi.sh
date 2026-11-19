#!/bin/bash

# Wi-Fi Menu for NetworkManager + Wofi

# Enable Wi-Fi if disabled
if [[ "$(nmcli radio wifi)" == "disabled" ]]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Wi-Fi Enabled"
    sleep 2
fi

# Current active connection
ACTIVE=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)

# Build Wi-Fi list
WIFI_LIST=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | awk -F: '
!seen[$1]++ {
    if ($3 == "") 
        printf "  %s  [%s%%]\n", $1, $2;
    else
        printf "󰖩  %s  [%s%%]  \n", $1, $2;
}')

# Add extra options
MENU=$(printf "󰓛  Disconnect\n  Toggle Wi-Fi\n%s" "$WIFI_LIST")

# Wofi selection
# CHOSEN=$(echo "$MENU" | wofi --dmenu --prompt "Wi-Fi")
CHOSEN=$(echo "$MENU" | rofi -dmenu -i -p "Wi-Fi")
# Exit if cancelled
[ -z "$CHOSEN" ] && exit 0

# Toggle Wi-Fi
if [[ "$CHOSEN" == *"Toggle Wi-Fi"* ]]; then
    if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
        nmcli radio wifi off
        notify-send "Wi-Fi" "Disabled"
    else
        nmcli radio wifi on
        notify-send "Wi-Fi" "Enabled"
    fi
    exit 0
fi

# Disconnect
if [[ "$CHOSEN" == *"Disconnect"* ]]; then
    nmcli connection down id "$ACTIVE"
    notify-send "Wi-Fi" "Disconnected from $ACTIVE"
    exit 0
fi

# Extract SSID
# SSID=$(echo "$CHOSEN" | sed 's/^󰖩  //' | sed 's/  \[.*//')
SSID=$(echo "$CHOSEN" | sed -E 's/^[^ ]+[[:space:]]+//' | sed 's/  \[.*//')

# Check if saved connection exists
# if nmcli connection show | grep -q "^$SSID"; then
if nmcli -t -f NAME connection show | grep -Fxq "$SSID"; then
    nmcli connection up "$SSID"
    
    if [ $? -eq 0 ]; then
        notify-send "Wi-Fi Connected" "Connected to $SSID ✨"
    else
        notify-send "Wi-Fi Error" "Failed to connect to $SSID"
    fi

    exit 0
fi

# Ask password only for new networks
# PASSWORD=$(wofi --dmenu --password --prompt "Password for $SSID")
PASSWORD=$(rofi -dmenu -password -p "Password for $SSID")

[ -z "$PASSWORD" ] && exit 0

# Connect
nmcli dev wifi connect "$SSID" password "$PASSWORD"

if [ $? -eq 0 ]; then
    notify-send "Wi-Fi Connected" "Connected to $SSID ✨"
else
    notify-send "Wi-Fi Error" "Wrong password or connection failed"
fi
