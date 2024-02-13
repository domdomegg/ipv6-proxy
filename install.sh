#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sed "s#PATH_TO_IPV6_PROXY#$DIR#g" | sudo tee /etc/systemd/system/ipv6-proxy.service
sudo systemctl daemon-reload
sudo systemctl enable --now ipv6-proxy.service
