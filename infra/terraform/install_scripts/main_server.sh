#!/bin/bash
set -euo pipefail

curl -sfL https://get.k3s.io | K3S_TOKEN='dNBAJVvy4vI+hy7ePb/MkJT0r8b7L3CRxdY6T5d2eFdo68/7PmcXIBdLJDar0dL+' sh -s - server \
  --node-name rk4-k3s-main-server \
  --node-ip 10.42.1.10 \
  --advertise-address 10.42.1.10 \
  --flannel-iface enp7s0 \
  --cluster-cidr 10.244.0.0/16 \
  --service-cidr 10.245.0.0/16 \
  --cluster-dns 10.245.0.10 \
  --tls-san 10.42.1.20 \
  --tls-san 5.78.162.199 \
  --cluster-init
  # --tls-san kube.rk4.home \
  # --tls-san rk4-k3s-main-server \
  # --tls-san rk4-k3s-server-2 \
  # --tls-san rk4-k3s-server-3 \
  # --tls-san 10.42.1.10 \
