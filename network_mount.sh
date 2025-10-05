#!/bin/bash

# macOS Network Auto-Mount Script
# Automatically mounts SMB shares when connected to specified Wi-Fi networks

# Configuration - Update these values for your setup
TARGET_NETWORK="YourNetworkName"
SHARE_SERVER="your-server-ip-or-hostname"  
SHARE_PATH="your-share-name"
USERNAME="your-username"
MOUNT_POINT="/tmp/hidden_shares"

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
    
    # Prompt for password if not using keychain
    # For automatic mounting, consider storing credentials in keychain
    log_message "Attempting to mount //$USERNAME@$SHARE_SERVER/$SHARE_PATH"
    
    # Mount the share (will prompt for password)
    mount -t smbfs "//$USERNAME@$SHARE_SERVER/$SHARE_PATH" "$MOUNT_POINT/$SHARE_PATH" 2>>"$LOG_FILE"
    
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