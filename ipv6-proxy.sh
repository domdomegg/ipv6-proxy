#!/bin/bash

set -euo pipefail

start_processes() {
    echo "Starting proxy..."
    TARGET=$(dig +short AAAA "$(cat target.txt)" | head -n1)
    command1="sudo socat TCP4-LISTEN:80,fork,su=nobody,reuseaddr TCP6:[$TARGET]:80"
    command2="sudo socat TCP4-LISTEN:443,fork,su=nobody,reuseaddr TCP6:[$TARGET]:443"

    # Run commands in the background
    $command1 &
    pid1=$!
    $command2 &
    pid2=$!

    echo "Processes started with PIDs: $pid1, $pid2"
}

stop_processes() {
    echo "Stopping proxy..."
    kill -9 $pid1 $pid2 2>/dev/null
}

if [ ! -f "target.txt" ]; then
    echo "No target.txt found! Create one with the target domain."
fi

start_processes
while true; do
    sleep 3600 # Restart every hour

    stop_processes
    start_processes
done
