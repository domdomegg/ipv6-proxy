#!/bin/bash

set -euo pipefail

# Prints the IPv6 addresses for the target domain (one per line), or fails if there are none.
# dig +short may print CNAMEs before the addresses, so keep only lines that look like IPv6.
resolve_targets() {
    dig +short +time=5 +tries=2 AAAA "$(cat target.txt)" | grep -E '^[0-9a-fA-F:]*:[0-9a-fA-F:]*$'
}

start_processes() {
    echo "Starting proxy to $TARGET..."
    command1="socat TCP4-LISTEN:80,fork,su=nobody,reuseaddr,backlog=128 TCP6:[$TARGET]:80"
    command2="socat TCP4-LISTEN:443,fork,su=nobody,reuseaddr,backlog=128 TCP6:[$TARGET]:443"

    # Run commands in the background
    $command1 &
    pid1=$!
    $command2 &
    pid2=$!

    echo "Processes started with PIDs: $pid1, $pid2"
}

stop_processes() {
    echo "Stopping proxy..."
    kill -9 "$pid1" "$pid2" 2>/dev/null || true
    wait "$pid1" "$pid2" 2>/dev/null || true
}

# systemd starts us in /, so look for target.txt next to this script
cd "$(dirname "$0")"

if [ ! -f "target.txt" ]; then
    echo "No target.txt found! Create one with the target domain."
    exit 1
fi

if ! TARGETS=$(resolve_targets); then
    echo "Failed to resolve an IPv6 address for $(cat target.txt)"
    exit 1
fi
TARGET=$(head -n1 <<< "$TARGETS")

start_processes
while true; do
    sleep 60

    # Exit on a failed lookup; systemd restarts us and retries
    if ! TARGETS=$(resolve_targets); then
        echo "Failed to resolve an IPv6 address for $(cat target.txt)"
        exit 1
    fi

    # Only restart if our current address is no longer in DNS (avoids churn with round-robin records)
    if ! grep -qxF "$TARGET" <<< "$TARGETS"; then
        NEW_TARGET=$(head -n1 <<< "$TARGETS")
        echo "Target changed from $TARGET to $NEW_TARGET"
        stop_processes
        TARGET=$NEW_TARGET
        start_processes
    fi
done
