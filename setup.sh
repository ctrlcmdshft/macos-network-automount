#!/bin/bash

echo "=== Network Share LaunchAgent Setup ==="
echo ""

# Get current network name
CURRENT_NETWORK=$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //')
if [ -n "$CURRENT_NETWORK" ]; then
    echo "Current Wi-Fi Network: $CURRENT_NETWORK"
    echo ""
fi

echo "Please provide the following information:"
echo ""

# Get target network
read -p "Target Network Name [$CURRENT_NETWORK]: " TARGET_NETWORK
TARGET_NETWORK=${TARGET_NETWORK:-$CURRENT_NETWORK}

# Get server details
read -p "Server IP/Hostname: " SHARE_SERVER
read -p "Share Name: " SHARE_PATH
read -p "Username: " USERNAME

# Ask about keychain
echo ""
read -p "Use keychain to store password securely? (y/n): " USE_KEYCHAIN_PROMPT
if [[ $USE_KEYCHAIN_PROMPT =~ ^[Yy]$ ]]; then
    USE_KEYCHAIN="true"
    SCRIPT_TO_USE="network_mount_enhanced.sh"
else
    USE_KEYCHAIN="false"
    SCRIPT_TO_USE="network_mount.sh"
fi

echo ""
echo "Configuration Summary:"
echo "  Network: $TARGET_NETWORK"
echo "  Server: $SHARE_SERVER"
echo "  Share: $SHARE_PATH"
echo "  Username: $USERNAME"
echo "  Use Keychain: $USE_KEYCHAIN"
echo ""

read -p "Proceed with configuration? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Update the script with user's configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$SCRIPT_DIR/$SCRIPT_TO_USE"

sed -i '' "s/TARGET_NETWORK=\"YourNetworkName\"/TARGET_NETWORK=\"$TARGET_NETWORK\"/" "$SCRIPT_FILE"
sed -i '' "s/SHARE_SERVER=\"your-server-ip-or-hostname\"/SHARE_SERVER=\"$SHARE_SERVER\"/" "$SCRIPT_FILE"
sed -i '' "s/SHARE_PATH=\"your-share-name\"/SHARE_PATH=\"$SHARE_PATH\"/" "$SCRIPT_FILE"
sed -i '' "s/USERNAME=\"your-username\"/USERNAME=\"$USERNAME\"/" "$SCRIPT_FILE"

if [ "$USE_KEYCHAIN" = "true" ]; then
    sed -i '' "s/USE_KEYCHAIN=false/USE_KEYCHAIN=true/" "$SCRIPT_FILE"
fi

# Update LaunchAgent plist to use the correct script
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.networkmount.plist"
sed -i '' "s|<string>.*network_mount.*\.sh</string>|<string>$SCRIPT_DIR/$SCRIPT_TO_USE</string>|" "$PLIST_FILE"

echo "✓ Configuration updated"

# Set up keychain if requested
if [ "$USE_KEYCHAIN" = "true" ]; then
    echo ""
    echo "Setting up keychain password..."
    "$SCRIPT_FILE" setup-keychain
fi

# Load the LaunchAgent
echo ""
echo "Loading LaunchAgent..."
launchctl unload "$PLIST_FILE" 2>/dev/null  # Unload if already loaded
launchctl load "$PLIST_FILE"

if [ $? -eq 0 ]; then
    echo "✓ LaunchAgent loaded successfully"
else
    echo "✗ Failed to load LaunchAgent"
    exit 1
fi

echo ""
echo "Setup complete! The LaunchAgent will now:"
echo "  • Monitor network changes"
echo "  • Mount the share when connected to '$TARGET_NETWORK'"
echo "  • Unmount the share when disconnected"
echo "  • Mount point: /tmp/hidden_shares/$SHARE_PATH"
echo ""
echo "Useful commands:"
echo "  • Test configuration: $SCRIPT_DIR/$SCRIPT_TO_USE test"
echo "  • View logs: tail -f ~/Library/Logs/network_mount.log"
echo "  • Unload LaunchAgent: launchctl unload ~/Library/LaunchAgents/com.user.networkmount.plist"
echo ""