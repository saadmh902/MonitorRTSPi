#!/bin/bash
# Check if VLC is running, if it crashes reopen VLC
# Pings RTSP server, if it fails over and over again close VLC and ping RTSP server until it is open, then relaunch VLC

CHECK_INTERVAL=10  # Interval to check VLC logs and status
RESTART_INTERVAL=604800 # Time in seconds to restart VLC (7 days)
PING_INTERVAL=1     # Ping interval in seconds
MAX_FAILED_PINGS=6  # Number of failed pings before closing VLC
LOG_FILES=(
    "$(dirname "$0")/vlc-log.txt"
    "$(dirname "$0")/vlc_log.txt"
)
RTSP_INFO_FILE="$(dirname "$0")/rtsp_url.txt"  # File containing the RTSP URL
RTSP_SERVER_IP_FILE="$(dirname "$0")/rtsp_server_ip.txt"  # File containing the RTSP Server IP
OFFLINE_LOG_FILE="$(dirname "$0")/OfflineLog.txt"  # File to log offline durations
SETTINGS_FILE="$(dirname "$0")/MonitorRTSPi_Settings.txt"  # Settings file for DebugMode

# Default settings
DEBUG_MODE=0

# Function to check for settings file and create if not exist
function check_settings_file {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo "DebugMode=0" > "$SETTINGS_FILE"
        chmod 644 "$SETTINGS_FILE"
        echo "$(date): Created settings file with default DebugMode=0."
    fi

    # Read DebugMode setting
    if [[ -f "$SETTINGS_FILE" ]]; then
        DEBUG_MODE=$(grep -oP '(?<=DebugMode=)\d+' "$SETTINGS_FILE")
        echo "$(date): DebugMode is set to $DEBUG_MODE."
    fi
}

# Function to read the IP address from RTSP_ServerIP file
function get_target_ip {
    if [[ -f "$RTSP_SERVER_IP_FILE" ]]; then
        TARGET_IP=$(< "$RTSP_SERVER_IP_FILE")
        echo "$(date): Read IP: $TARGET_IP from RTSP server IP file."
    else
        echo "$(date): Error - RTSP server IP file not found!"
        exit 1
    fi
}

function start_vlc {
    # Read the RTSP URL from the file
    local rtsp_url
    rtsp_url=$(< "$RTSP_INFO_FILE")

    echo "$(date): Starting VLC with stream: $rtsp_url..."
    sudo -u "$CURRENT_USER" vlc --play-and-exit --fullscreen "$rtsp_url" > /dev/null 2> vlc_error.log &
    # Wait for VLC to launch
    while ! pgrep -x "vlc" > /dev/null; do
        sleep 1  # Wait for 1 second before checking again
    done

    echo "$(date): VLC started."
}

function check_vlc_logs {
    for LOG_FILE in "${LOG_FILES[@]}"; do
        if [[ -f "$LOG_FILE" ]]; then
            if grep -q -e "stream is not reachable" -e "Failed to connect with rtsp" "$LOG_FILE"; then
                echo "$(date): Stream is down in $LOG_FILE! Handling VLC based on DebugMode..."

                # If DebugMode is 1, handle it differently
                if [[ "$DEBUG_MODE" -eq 1 ]]; then
                    echo "$(date): DebugMode is 1, killing VLC after consecutive failed pings."
                    check_ping  # This will handle the ping checks
                else
                    echo "$(date): DebugMode is 0, VLC will remain open."
                fi
                return
            fi
        fi
    done
}

function restart_vlc {
    echo "$(date): Restarting VLC..."
    pkill vlc  # Kill VLC
    sleep 2    # Wait a moment before restarting
    start_vlc  # Start VLC again
    echo "$(date): VLC has been restarted."  # Echo message when VLC restarts
}

function check_vlc_playback {
    # Check if VLC is running
    if pgrep vlc > /dev/null; then
        echo "$(date): VLC is running."
    else
        echo "$(date): VLC is not running. Starting VLC..."
        start_vlc
    fi
}

function check_ping {
    local failed_count=0
    local offline_start_time

    while true; do
        if ping -c 1 "$TARGET_IP" > /dev/null; then
            echo "$(date): Ping successful to $TARGET_IP."

            # If VLC was offline, calculate offline time and log it
            if [[ -n "$offline_start_time" ]]; then
                local offline_end_time=$(date +%s)
                local offline_duration=$((offline_end_time - offline_start_time))
                echo "Seconds offline: $offline_duration" >> "$OFFLINE_LOG_FILE"
                offline_start_time=""
            fi

            return 0
        else
            echo "$(date): Ping failed to $TARGET_IP."
            ((failed_count++))

            if (( failed_count >= MAX_FAILED_PINGS )); then
                echo "$(date): $MAX_FAILED_PINGS consecutive pings failed."

                # If DebugMode is 1, kill VLC immediately
                if [[ "$DEBUG_MODE" -eq 1 ]]; then
                    echo "$(date): DebugMode is 1, killing VLC after failed pings."
                    pkill vlc  # Kill VLC
                    wait_for_ping_before_restart  # Wait for a successful ping before restarting
                    return
                else
                    # DebugMode=0: Wait for reconnection before killing VLC
                    echo "$(date): DebugMode is 0, waiting for reconnection before killing VLC."
                    offline_start_time=$(date +%s)
                    wait_for_ping_before_restart
                    return
                fi
            fi
        fi
        sleep "$PING_INTERVAL"
    done
}

function wait_for_ping_before_restart {
    while true; do
        if ping -c 1 "$TARGET_IP" > /dev/null; then
            echo "$(date): Successful ping to $TARGET_IP. Restarting VLC..."
            start_vlc
            return
        fi
        sleep "$PING_INTERVAL"
    done
}

# Check and create settings file if needed
check_settings_file

# Read the IP address from RTSP_ServerIP at the start
get_target_ip

# Start VLC when the script is launched
start_vlc

# Keep track of the last restart time
last_restart_time=$(date +%s)

# Main loop to monitor VLC
while true; do
    check_vlc_logs
    check_vlc_playback
    check_ping

    # Get the current time
    current_time=$(date +%s)

    # Check if it’s time to restart VLC
    if (( current_time - last_restart_time >= RESTART_INTERVAL )); then
        echo "$(date): Restarting VLC after $RESTART_INTERVAL seconds."
        restart_vlc
        last_restart_time=$current_time  # Update the last restart time
    fi

    sleep "$CHECK_INTERVAL"
done
