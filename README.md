# macOS Network Auto-Mount

Automatically mount an SMB share on macOS when you join a specific Wi-Fi network, and unmount it when you leave.

Current build: `0.1.0-beta.1`

## What It Does

This project installs a per-user LaunchAgent that watches macOS network configuration changes. Each time the network changes, the agent runs `network_mount_enhanced.sh`, which:

1. Detects the active Wi-Fi interface dynamically.
2. Reads your local config from `~/Library/Application Support/NetworkAutoMount/config.sh`.
3. Checks whether the current SSID matches your target network.
4. Mounts the configured SMB share if it matches.
5. Unmounts the share if it does not.

The share is mounted under:

```bash
~/Library/Caches/NetworkAutoMount/mounts/<share-name>
```

By default the share is mounted with `nobrowse,automounted`, which keeps it out of the usual Finder browsing flow. You can now make that optional during setup.

## Files

- `setup.sh`: interactive setup that writes your local config and loads the LaunchAgent
- `install.sh`: writes the LaunchAgent plist
- `network_mount_enhanced.sh`: main runtime script used by the LaunchAgent
- `network_mount.sh`: compatibility wrapper that forwards to the main script
- `config.example.sh`: example config layout

## Installation

```bash
git clone https://github.com/yourusername/macos-network-automount.git
cd macos-network-automount
chmod +x *.sh
./setup.sh
```

`setup.sh` asks for:

- target Wi-Fi network name
- SMB server hostname or IP
- share name
- username
- auth mode
- whether the share should appear in Finder

It writes the resulting config to:

```bash
~/Library/Application Support/NetworkAutoMount/config.sh
```

The generated config includes:

- `TARGET_NETWORK`
- `SHARE_SERVER`
- `SHARE_PATH`
- `USERNAME`
- `AUTH_MODE`
- `MOUNT_ROOT`
- `MOUNT_NAME`
- `SHOW_IN_FINDER`
- `MOUNT_OPTIONS`

## Auth Modes

There are two supported auth modes:

1. `nsmb`
   Stores credentials in `~/Library/Preferences/nsmb.conf` so the LaunchAgent can mount the share unattended. This is plain-text storage protected by file permissions, not Keychain.
2. `system`
   Does not store credentials. This only works if macOS already has a usable SMB session or the share can be mounted without a password prompt.

If you want unattended background mounts, use `nsmb`.

## Config Notes

`SHOW_IN_FINDER` controls the default mount visibility behavior:

- `false`: mount with `nobrowse,automounted`
- `true`: mount with `automounted`

If you need something more specific, you can still override `MOUNT_OPTIONS` directly in `~/Library/Application Support/NetworkAutoMount/config.sh`. When `MOUNT_OPTIONS` is set manually, that value takes precedence over the derived Finder visibility setting.

## Usage

After setup, everything runs automatically. Useful manual commands:

```bash
./network_mount_enhanced.sh status
tail -f ~/Library/Logs/network_mount.log
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.user.networkmount.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.networkmount.plist
launchctl kickstart -k gui/$(id -u)/com.user.networkmount
```

## How It Works

The LaunchAgent plist lives at:

```bash
~/Library/LaunchAgents/com.user.networkmount.plist
```

It is configured with:

- `RunAtLoad`: evaluate the mount as soon as the agent is loaded
- `WatchPaths=/Library/Preferences/SystemConfiguration`: rerun when macOS network state changes
- stdout and stderr log files under `~/Library/Logs/`

The runtime script does not keep a daemon process alive. It is invoked on demand by `launchd`, checks current state, then exits.

## Why This Version Is Better

Compared with the original layout, this version:

- stops setup from editing checked-in scripts in place
- detects the Wi-Fi device instead of assuming `en0`
- uses a generated local config file outside the repo
- uses modern `launchctl bootstrap/bootout/kickstart` flow
- lets you choose whether the mount should appear in Finder
- exposes a `status` command for debugging

## Troubleshooting

Check the current status:

```bash
./network_mount_enhanced.sh status
```

Check runtime logs:

```bash
tail -50 ~/Library/Logs/network_mount.log
tail -50 ~/Library/Logs/network_mount_stderr.log
```

Check whether the agent is loaded:

```bash
launchctl print gui/$(id -u)/com.user.networkmount
```

Check your current Wi-Fi network:

```bash
networksetup -getairportnetwork "$(networksetup -listallhardwareports | awk '/Hardware Port: (Wi-Fi|AirPort)/{getline; print $2; exit}')"
```

## Uninstall

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.user.networkmount.plist
rm -f ~/Library/LaunchAgents/com.user.networkmount.plist
rm -f ~/Library/Application\ Support/NetworkAutoMount/config.sh
```

If you used `nsmb` auth and want to remove the stored SMB credentials, edit:

```bash
~/Library/Preferences/nsmb.conf
```

## License

MIT. See [LICENSE](LICENSE).
