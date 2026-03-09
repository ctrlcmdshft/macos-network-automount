#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.networkmount.plist"
SCRIPT_FILE="$SCRIPT_DIR/network_mount_enhanced.sh"
LOG_DIR="$HOME/Library/Logs"

echo "Creating LaunchAgent configuration..."

mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"

cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.networkmount</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_FILE</string>
        <string>run</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>WatchPaths</key>
    <array>
        <string>/Library/Preferences/SystemConfiguration</string>
    </array>
    
    <key>StandardOutPath</key>
    <string>$LOG_DIR/network_mount_stdout.log</string>

    <key>StandardErrorPath</key>
    <string>$LOG_DIR/network_mount_stderr.log</string>
    
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
echo "2. The LaunchAgent will be loaded during setup"
