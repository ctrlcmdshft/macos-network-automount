#!/bin/bash

# macOS Network Auto-Mount Script (Enhanced)
# Automatically mounts SMB shares with optional macOS Keychain integration

# Configuration - Update these values for your setup  
TARGET_NETWORK="YourNetworkName"
SHARE_SERVER="your-server-ip-or-hostname"
SHARE_PATH="your-share-name" 
USERNAME="your-username"
MOUNT_POINT="/tmp/hidden_shares"
KEYCHAIN_SERVICE="NetworkShare"
USE_KEYCHAIN=false

# Logging
LOG_FILE="$HOME/Library/Logs/network_mount.log"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to get current Wi-Fi network
get_current_network() {
    networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' | tr -d '\n'
}

# Function to get password from keychain
get_keychain_password() {
    security find-generic-password -w -s "$KEYCHAIN_SERVICE" -a "$USERNAME" 2>/dev/null
}

# Function to store password in keychain
store_keychain_password() {
    echo "Enter password for $USERNAME@$SHARE_SERVER:"
    read -s password
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$USERNAME" -w "$password"
    echo "Password stored in keychain"
}

# Function to check if share is already mounted
is_mounted() {
    mount | grep -q "$MOUNT_POINT/$SHARE_PATH"
    return $?
}

# Function to mount the share
mount_share() {
    if is_mounted; then
        log_message "Share already mounted at $MOUNT_POINT/$SHARE_PATH"
        return 0
    fi
    
    # Create mount point if it doesn't exist
    mkdir -p "$MOUNT_POINT/$SHARE_PATH"
    
    log_message "Attempting to mount //$USERNAME@$SHARE_SERVER/$SHARE_PATH"
    
    if [ "$USE_KEYCHAIN" = true ]; then
        PASSWORD=$(get_keychain_password)
        if [ -n "$PASSWORD" ]; then
            # Mount with password from keychain
            echo "$PASSWORD" | mount -t smbfs "//$USERNAME@$SHARE_SERVER/$SHARE_PATH" "$MOUNT_POINT/$SHARE_PATH" 2>>"$LOG_FILE"
        else
            log_message "No password found in keychain for $USERNAME"
            return 1
        fi
    else
        # Mount without stored password (will prompt if needed)
        mount -t smbfs "//$USERNAME@$SHARE_SERVER/$SHARE_PATH" "$MOUNT_POINT/$SHARE_PATH" 2>>"$LOG_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Successfully mounted share at $MOUNT_POINT/$SHARE_PATH"
        return 0
    else
        log_message "Failed to mount share"
        return 1
    fi
}

# Function to unmount the share
unmount_share() {
    if is_mounted; then
        log_message "Unmounting share at $MOUNT_POINT/$SHARE_PATH"
        umount "$MOUNT_POINT/$SHARE_PATH" 2>>"$LOG_FILE"
        if [ $? -eq 0 ]; then
            log_message "Successfully unmounted share"
            rmdir "$MOUNT_POINT/$SHARE_PATH" 2>/dev/null
        else
            log_message "Failed to unmount share"
        fi
    fi
}

# Handle command line arguments
case "$1" in
    "setup-keychain")
        store_keychain_password
        exit 0
        ;;
    "test")
        echo "Current network: $(get_current_network)"
        echo "Target network: $TARGET_NETWORK"
        if [ "$(get_current_network)" = "$TARGET_NETWORK" ]; then
            echo "✓ Connected to target network"
        else
            echo "✗ Not connected to target network"
        fi
        exit 0
        ;;
esac

# Main logic
CURRENT_NETWORK=$(get_current_network)
log_message "Current network: '$CURRENT_NETWORK', Target network: '$TARGET_NETWORK'"

if [ "$CURRENT_NETWORK" = "$TARGET_NETWORK" ]; then
    log_message "Connected to target network, mounting share..."
    mount_share
else
    log_message "Not connected to target network, unmounting share if mounted..."
    unmount_share
fi