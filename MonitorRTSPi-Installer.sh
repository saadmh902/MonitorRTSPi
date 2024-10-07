#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Determine the user and their home directory based on the script's location
USER_HOME=$(getent passwd "$(stat -c '%U' "$SCRIPT_DIR")" | cut -d: -f6)
CURRENT_USER=$(basename "$USER_HOME")  # Get the current user's username from the home directory

# Define the files and URLs
DIRECTORY="$USER_HOME"
FILES=(
    "$DIRECTORY/launch.sh"
    "$DIRECTORY/newstart.sh"
)
AUTOSTART_FILE="/etc/xdg/autostart/launch.desktop"
RTSP_URL_FILE="$DIRECTORY/rtsp_url.txt"        # File for RTSP Stream URL
RTSP_SERVER_IP_FILE="$DIRECTORY/rtsp_server_ip.txt"  # File for RTSP Server IP

# URL to download newstart.sh
NEWSTART_URL="https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/home/user/newstart.sh"

# Download the newstart.sh file
echo "Downloading newstart.sh..."
curl -o "${FILES[1]}" "$NEWSTART_URL"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Error downloading newstart.sh. Exiting."
    exit 1
fi

# Create launch.sh file with appropriate content
echo "Creating launch.sh..."
{
    echo "#!/bin/bash"
    echo "# Opens the terminal and runs newstart.sh script to view connection to camera, and writes log"
    echo "lxterminal --command=\"$DIRECTORY/newstart.sh\" > \"$DIRECTORY/logged.log\""
} > "${FILES[0]}"

# Create the launch.desktop file with the appropriate content
echo "Creating launch.desktop..."
{
    echo "[Desktop Entry]"
    echo "Type=Application"
    echo "Name=LaunchScript"
    echo "Exec=bash -c \"DISPLAY=:0 $DIRECTORY/launch.sh\""
    echo "X-GNOME-Autostart-enabled=true"
} > "$AUTOSTART_FILE"

# Request user input for RTSP Stream URL
read -p "RTSP Stream URL (Example: rtsp://admin:password@192.168.0.1:554/ch1/1/): " RTSP_URL

# Write the RTSP URL to rtsp_url.txt
echo "$RTSP_URL" > "$RTSP_URL_FILE"
echo "RTSP Stream URL saved to $RTSP_URL_FILE."

# Request user input for RTSP Server IP
read -p "RTSP Server IP (Example: 192.168.0.1): " RTSP_SERVER_IP

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

# Change ownership of newstart.sh to the current user at the end
sudo chown "$CURRENT_USER:$CURRENT_USER" "${FILES[1]}"

echo "All permissions set successfully."
