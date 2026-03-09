#!/bin/bash

set -u

APP_NAME="NetworkAutoMount"
CONFIG_FILE="${NETWORK_MOUNT_CONFIG:-$HOME/Library/Application Support/$APP_NAME/config.sh}"
LOG_FILE="${NETWORK_MOUNT_LOG:-$HOME/Library/Logs/network_mount.log}"
DEFAULT_MOUNT_ROOT="$HOME/Library/Caches/$APP_NAME/mounts"

log_message() {
    mkdir -p "$(dirname "$LOG_FILE")"
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

fatal() {
    log_message "ERROR: $1"
    printf '%s\n' "$1" >&2
    exit 1
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        fatal "Config not found at $CONFIG_FILE. Run ./setup.sh first."
    fi

    # shellcheck disable=SC1090
    . "$CONFIG_FILE"

    SHARE_PATH="${SHARE_PATH:-${SHARE_NAME:-}}"
    MOUNT_ROOT="${MOUNT_ROOT:-$DEFAULT_MOUNT_ROOT}"
    AUTH_MODE="${AUTH_MODE:-system}"
    SHOW_IN_FINDER="${SHOW_IN_FINDER:-false}"
    MOUNT_NAME="${MOUNT_NAME:-$(printf '%s' "$SHARE_PATH" | tr '/:' '__')}"
    MOUNT_OPTIONS="${MOUNT_OPTIONS:-$(build_mount_options)}"

    : "${TARGET_NETWORK:?Missing TARGET_NETWORK in $CONFIG_FILE}"
    : "${SHARE_SERVER:?Missing SHARE_SERVER in $CONFIG_FILE}"
    : "${SHARE_PATH:?Missing SHARE_PATH in $CONFIG_FILE}"
    : "${USERNAME:?Missing USERNAME in $CONFIG_FILE}"
}

build_mount_options() {
    if [ "${SHOW_IN_FINDER:-false}" = "true" ]; then
        printf '%s\n' "automounted"
    else
        printf '%s\n' "nobrowse,automounted"
    fi
}

find_wifi_device() {
    networksetup -listallhardwareports 2>/dev/null | awk '
        /Hardware Port: (Wi-Fi|AirPort)/ {
            getline
            if ($1 == "Device:") {
                print $2
                exit
            }
        }
    '
}

get_current_network() {
    local wifi_device

    wifi_device="$(find_wifi_device)"
    if [ -z "$wifi_device" ]; then
        return 0
    fi

    networksetup -getairportnetwork "$wifi_device" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p' | tr -d '\n'
}

get_mount_path() {
    printf '%s/%s' "$MOUNT_ROOT" "$MOUNT_NAME"
}

is_mounted() {
    local mount_path

    mount_path="$(get_mount_path)"
    /sbin/mount | awk -v target="$mount_path" '$3 == target { found = 1 } END { exit found ? 0 : 1 }'
}

mount_share() {
    local mount_path mount_url rc

    mount_path="$(get_mount_path)"
    mount_url="//$USERNAME@$SHARE_SERVER/$SHARE_PATH"

    if is_mounted; then
        log_message "Share already mounted at $mount_path"
        return 0
    fi

    mkdir -p "$mount_path"
    log_message "Attempting mount for //$USERNAME@$SHARE_SERVER/$SHARE_PATH at $mount_path"

    case "$AUTH_MODE" in
        nsmb)
            /sbin/mount -t smbfs -N -o "$MOUNT_OPTIONS" "$mount_url" "$mount_path" >> "$LOG_FILE" 2>&1
            ;;
        system)
            /sbin/mount -t smbfs -o "$MOUNT_OPTIONS,nopassprompt" "$mount_url" "$mount_path" >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_message "Unknown AUTH_MODE '$AUTH_MODE'"
            return 1
            ;;
    esac

    rc=$?
    if [ "$rc" -eq 0 ]; then
        log_message "Successfully mounted share at $mount_path"
        return 0
    fi

    log_message "Failed to mount share (exit code $rc)"
    rmdir "$mount_path" 2>/dev/null || true
    return "$rc"
}

unmount_share() {
    local mount_path rc

    mount_path="$(get_mount_path)"
    if ! is_mounted; then
        return 0
    fi

    log_message "Unmounting share at $mount_path"
    /sbin/umount "$mount_path" >> "$LOG_FILE" 2>&1
    rc=$?

    if [ "$rc" -eq 0 ]; then
        log_message "Successfully unmounted share"
        rmdir "$mount_path" 2>/dev/null || true
        return 0
    fi

    log_message "Failed to unmount share (exit code $rc)"
    return "$rc"
}

print_status() {
    local current_network mount_path

    current_network="$(get_current_network)"
    mount_path="$(get_mount_path)"

    printf 'Current network: %s\n' "${current_network:-<not connected>}"
    printf 'Target network: %s\n' "$TARGET_NETWORK"
    printf 'Share: //%s@%s/%s\n' "$USERNAME" "$SHARE_SERVER" "$SHARE_PATH"
    printf 'Mount path: %s\n' "$mount_path"
    printf 'Auth mode: %s\n' "$AUTH_MODE"
    printf 'Show in Finder: %s\n' "$SHOW_IN_FINDER"

    if is_mounted; then
        printf 'Mounted: yes\n'
    else
        printf 'Mounted: no\n'
    fi
}

run_once() {
    local current_network

    current_network="$(get_current_network)"
    log_message "Current network: '${current_network:-<none>}', target network: '$TARGET_NETWORK'"

    if [ -n "$current_network" ] && [ "$current_network" = "$TARGET_NETWORK" ]; then
        log_message "Connected to target network, mounting share"
        mount_share
    else
        log_message "Not connected to target network, unmounting share if needed"
        unmount_share
    fi
}

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [run|status|test]

  run     Evaluate the current network and mount or unmount the share
  status  Print the current config and mount status
  test    Alias for status
EOF
}

main() {
    local command

    command="${1:-run}"
    case "$command" in
        run)
            load_config
            run_once
            ;;
        status|test)
            load_config
            print_status
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
