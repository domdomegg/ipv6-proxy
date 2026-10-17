#!/bin/bash

set -euo pipefail

sudo systemctl disable --now ipv6-proxy.service || true
sudo rm -f /etc/systemd/system/ipv6-proxy.service
sudo systemctl daemon-reload
