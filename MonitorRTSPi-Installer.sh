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
RTSP_SERVER_IP_FILE="$DIRECTORY/rtsp_server_ip.txt"  # File for RTSP Server IP

URLS=(
    "https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/etc/xdg/autostart/launch.desktop"
    "https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/home/user/newstart.sh"
)

# Download the autostart file and newstart.sh
echo "Downloading files..."
curl -o "$AUTOSTART_FILE" "${URLS[0]}"  # Download launch.desktop to /etc/xdg/autostart/
curl -o "${FILES[1]}" "${URLS[1]}"      # Download newstart.sh to home directory

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error downloading files. Exiting."
    exit 1
fi

# Create launch.sh file with appropriate content
echo "Creating launch.sh..."
cat << 'EOF' > "${FILES[0]}"
#!/bin/bash
# Opens the terminal and runs newstart.sh script to view connection to camera, and writes log
sudo lxterminal --command="$HOME/newstart.sh" > "$HOME/logged.log"
EOF

# Request user input for RTSP Stream URL
read -p "RTSP Stream URL (Example: rtsp://<USERNAME>:<PASSWORD>@<IP>:<Port>/ch1/1/): " RTSP_URL

# Write the RTSP URL to RTSPInfo.txt
echo "$RTSP_URL" > "$RTSP_INFO_FILE"
echo "RTSP Stream URL saved to $RTSP_INFO_FILE."

# Request user input for RTSP Server IP
read -p "RTSP Server IP (Example: <IP>): " RTSP_SERVER_IP

# Write the RTSP Server IP to rtsp_server_ip.txt
echo "$RTSP_SERVER_IP" > "$RTSP_SERVER_IP_FILE"
echo "RTSP Server IP saved to $RTSP_SERVER_IP_FILE."

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
