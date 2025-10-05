#!/bin/bash

# macOS Network Auto-Mount - Installation Script
# This script creates the necessary LaunchAgent configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.networkmount.plist"

echo "Creating LaunchAgent configuration..."

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Create the LaunchAgent plist file
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.networkmount</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/network_mount.sh</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>WatchPaths</key>
    <array>
        <string>/Library/Preferences/SystemConfiguration</string>
    </array>
    
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/network_mount_stdout.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/network_mount_stderr.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

echo "LaunchAgent created at: $PLIST_FILE"
echo ""
echo "Next steps:"
echo "1. Run ./setup.sh to configure your shares"
echo "2. The LaunchAgent will be automatically loaded during setup"