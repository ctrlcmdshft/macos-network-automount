# macOS Network Auto-Mount

Automatically mount network shares on macOS when connected to specific Wi-Fi networks. Shares are mounted to hidden locations that don't appear in Finder's sidebar.

## Overview

This tool uses macOS LaunchAgent to monitor network changes and automatically mount/unmount SMB shares based on your current Wi-Fi connection. Perfect for automatically accessing office file servers when at work, or home NAS when at home.

## Features

- **Network-aware mounting**: Only mounts when connected to specified Wi-Fi networks
- **Automatic cleanup**: Unmounts when disconnecting from networks  
- **Hidden from Finder**: Mount points won't clutter Finder sidebar
- **Secure credentials**: Optional macOS Keychain integration for passwords
- **Zero maintenance**: Set it once, works automatically
- **Comprehensive logging**: Debug issues easily with detailed logs
- **Easy setup**: Interactive configuration script

## Requirements

- macOS 10.12 or later
- SMB/CIFS network shares
- Wi-Fi connection for network detection

## Installation

1. **Download the project**:
   ```bash
   git clone https://github.com/yourusername/macos-network-automount.git
   cd macos-network-automount
   ```

2. **Run setup**:
   ```bash
   ./setup.sh
   ```

3. **Follow the prompts** to configure:
   - Target Wi-Fi network name
   - Server hostname or IP address  
   - Share name and username
   - Password storage preference

That's it! The system is now active and will automatically handle mounting/unmounting.

## Features

- **Network-aware mounting**: Only mounts when connected to specified Wi-Fi network
- **Hidden from Finder**: Mounts to `/tmp/hidden_shares/` which doesn't appear in Finder
- **Automatic cleanup**: Unmounts when disconnecting from the network
- **Secure password storage**: Optional macOS keychain integration
- **Comprehensive logging**: All activities logged for troubleshooting
- **Error handling**: Robust error checking and recovery

## Quick Start

1. Run the interactive setup:
   ```bash
   ~/Documents/GitHub/MountScript/setup_network_mount.sh
   ```

2. Follow the prompts to configure:
   - Target Wi-Fi network name
   - Server hostname/IP
   - Share name
   - Username
   - Password storage method (keychain recommended)

## Usage

Once configured, the system runs automatically via macOS LaunchAgent. No manual intervention required.

## How It Works

The system uses a macOS LaunchAgent that monitors network configuration changes. When you connect to your specified Wi-Fi network, it automatically mounts your configured shares to `/tmp/hidden_shares/` (hidden from Finder). When you disconnect, shares are automatically unmounted.

## Configuration Details

- **Mount location**: `/tmp/hidden_shares/[share-name]` (hidden from Finder)
- **LaunchAgent**: `~/Library/LaunchAgents/com.user.networkmount.plist`
- **Logs**: `~/Library/Logs/network_mount.log`
- **Credentials**: Stored in macOS Keychain (optional)

## Usage

After setup, everything works automatically. However, you can use these commands:

```bash
# Test current configuration
./network_mount_enhanced.sh test

# View real-time logs  
tail -f ~/Library/Logs/network_mount.log

# Reload the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.user.networkmount.plist
launchctl load ~/Library/LaunchAgents/com.user.networkmount.plist
```

## Troubleshooting

**LaunchAgent not working?**
```bash
# Check if loaded
launchctl list | grep com.user.networkmount

# View logs for errors
tail -20 ~/Library/Logs/network_mount.log
```

**Network not detected?**
```bash
# Test network detection
networksetup -getairportnetwork en0
```

**Mount failing?**
- Verify server is accessible: `ping your-server-name`
- Check credentials are correct
- Ensure SMB sharing is enabled on the server

## Uninstalling

```bash
# Stop the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.user.networkmount.plist

# Remove LaunchAgent file
rm ~/Library/LaunchAgents/com.user.networkmount.plist

# Remove keychain entry (if used)
security delete-generic-password -s "NetworkShare"

# Delete project folder
rm -rf /path/to/macos-network-automount
```

## Contributing

Pull requests welcome! Please ensure scripts are tested on macOS before submitting.

## License

MIT License - see [LICENSE](LICENSE) file for details.