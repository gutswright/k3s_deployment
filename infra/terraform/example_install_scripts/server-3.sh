#!/bin/bash
set -euo pipefail

# NODE_NAME="${NODE_NAME:?Set NODE_NAME to example-k3s-server-2 or example-k3s-server-3}"
# NODE_IP="${NODE_IP:?Set NODE_IP to this server's private IP, for example 10.0.1.12 or 10.0.1.13}"
# NODE_NAME="example-k3s-server-3"
# NODE_IP="10.0.1.13"

curl -sfL https://get.k3s.io | K3S_TOKEN='replace-with-a-long-random-cluster-token' sh -s - server \
  --node-ip "10.0.1.13" \
  --advertise-address "10.0.1.13" \
  --flannel-iface enp7s0 \
  --cluster-cidr 10.244.0.0/16 \
  --service-cidr 10.245.0.0/16 \
  --cluster-dns 10.245.0.10 \
  --server https://10.0.1.10:6443 \
  --tls-san 10.0.1.20 \
  --tls-san 203.0.113.20
