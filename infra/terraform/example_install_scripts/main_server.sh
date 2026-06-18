#!/bin/bash
set -euo pipefail

curl -sfL https://get.k3s.io | K3S_TOKEN='replace-with-a-long-random-cluster-token' sh -s - server \
  --node-name example-k3s-main-server \
  --node-ip 10.0.1.10 \
  --advertise-address 10.0.1.10 \
  --flannel-iface enp7s0 \
  --cluster-cidr 10.244.0.0/16 \
  --service-cidr 10.245.0.0/16 \
  --cluster-dns 10.245.0.10 \
  --tls-san 10.0.1.20 \
  --tls-san 203.0.113.20 \
  --cluster-init
  # --tls-san kube.example.internal \
  # --tls-san example-k3s-main-server \
  # --tls-san example-k3s-server-2 \
  # --tls-san example-k3s-server-3 \
  # --tls-san 10.0.1.10 \
