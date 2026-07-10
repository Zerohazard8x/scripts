#!/bin/bash

# Function to add a WiFi network
add_wifi_network() {
    local ssid="$1"

    # Check for 'cmd' command availability
    if type cmd &>/dev/null; then
        if cmd wifi connect-network "\"$ssid\"" open -r auto; then
            echo "Network $ssid added and enabled."
        else
            echo "Failed to add network $ssid using cmd."
        fi
    # Check for 'wpa_cli' command availability
    elif type wpa_cli &>/dev/null; then
        local network_id=$(wpa_cli add_network | awk 'END{print $NF}')
        if [[ -z "$network_id" ]]; then
            echo "Failed to add network: wpa_cli add_network failed."
            return
        fi

        wpa_cli set_network "$network_id" ssid "\"$ssid\"" &&
        wpa_cli set_network "$network_id" &&
        wpa_cli set_network "$network_id" mac_addr 1 &&
        wpa_cli enable_network "$network_id" &&
        wpa_cli save_config &&
        echo "Network $ssid added and enabled."
    else
        echo "No suitable command found to add network $ssid."
    fi
}

# android
# add_wifi_network() {
#     # adb shell "am start -n com.steinwurf.adbjoinwifi/.MainActivity -e ssid $ssid" # https://github.com/steinwurf/adb-join-wifi
#     adb shell "am start -n com.adbwifisettingsmanager/.WifiSettingsManagerActivity --esn newConnection -e ssid $(printf '%q' "$1")" # https://github.com/pr4bh4sh/adb-wifi-setting-manager
# }

# Temporarily set SELinux to permissive mode
local old_se=$(getenforce)
setenforce 0

# Add networks
add_wifi_network "_DarlingSquareFreeWifi_"

# Restore SELinux state
setenforce "$old_se"

exit