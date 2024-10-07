#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Determine the user and their home directory based on the script's location
USER_HOME=$(getent passwd "$(stat -c '%U' "$SCRIPT_DIR")" | cut -d: -f6)

# Define the files and URLs
DIRECTORY="$USER_HOME"
FILES=(
    "$DIRECTORY/launch.sh"
    "$DIRECTORY/newstart.sh"
)
AUTOSTART_FILE="/etc/xdg/autostart/launch.desktop"
RTSP_INFO_FILE="$DIRECTORY/RTSPInfo.txt"

URLS=(
    "https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/etc/xdg/autostart/launch.desktop"
    "https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/home/user/launch.sh"
    "https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/home/user/newstart.sh"
)

# Download the files
echo "Downloading files..."
curl -o "$AUTOSTART_FILE" "${URLS[0]}"  # Download launch.desktop to /etc/xdg/autostart/
curl -o "${FILES[0]}" "${URLS[1]}"      # Download launch.sh to home directory
curl -o "${FILES[1]}" "${URLS[2]}"      # Download newstart.sh to home directory

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error downloading files. Exiting."
    exit 1
fi

# Request user input for RTSP Stream URL
read -p "RTSP Stream URL (Example: rtsp://<USERNAME>:<PASSWORD>@<IP>:<Port>/ch1/1/): " RTSP_URL

# Write the RTSP URL to RTSPInfo.txt
echo "$RTSP_URL" > "$RTSP_INFO_FILE"
echo "RTSP Stream URL saved to $RTSP_INFO_FILE."

# Set the permissions for the directory
if [ -d "$DIRECTORY" ]; then
    chmod 775 "$DIRECTORY"  # Set read/write/execute for owner and group, read/execute for others
    echo "Set permissions for directory $DIRECTORY"
else
    echo "Directory $DIRECTORY does not exist."
fi

# Set the permissions for each file
for FILE in "${FILES[@]}"; do
    if [ -e "$FILE" ]; then
        chmod 664 "$FILE"  # Set read/write permissions for owner and group, read for others
        echo "Set permissions for $FILE"
    else
        echo "File $FILE does not exist."
    fi
done

# Make sure scripts are executable
chmod +x "$DIRECTORY/launch.sh"
chmod +x "$DIRECTORY/newstart.sh"

echo "All permissions set successfully."
