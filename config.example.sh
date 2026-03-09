#!/bin/bash

# Copy the values into:
# ~/Library/Application Support/NetworkAutoMount/config.sh
# or generate the file with ./setup.sh

TARGET_NETWORK='Office WiFi'
SHARE_SERVER='fileserver.local'
SHARE_PATH='Shared'
USERNAME='your-username'
AUTH_MODE='nsmb'
MOUNT_ROOT="$HOME/Library/Caches/NetworkAutoMount/mounts"
MOUNT_NAME='Shared'
SHOW_IN_FINDER='false'
MOUNT_OPTIONS='nobrowse,automounted'
