#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

tofu apply \
  -replace='module.nodes["main_server"].hcloud_server.this' \
  -replace='module.nodes["server_2"].hcloud_server.this' \
  -replace='module.nodes["server_3"].hcloud_server.this'
