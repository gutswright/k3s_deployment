# NODE_NAME="${NODE_NAME:?Set NODE_NAME to rk4-k3s-server-2 or rk4-k3s-server-3}"
# NODE_IP="${NODE_IP:?Set NODE_IP to this server's private IP, for example 10.42.1.12 or 10.42.1.13}"
# NODE_NAME="rk4-k3s-server-2"
# NODE_IP="10.42.1.12"

curl -sfL https://get.k3s.io | K3S_TOKEN='dNBAJVvy4vI+hy7ePb/MkJT0r8b7L3CRxdY6T5d2eFdo68/7PmcXIBdLJDar0dL+' sh -s - server \
  --node-ip  "10.42.1.13" \
  --advertise-address "10.42.1.13" \
  --flannel-iface enp7s0 \
  --cluster-cidr 10.244.0.0/16 \
  --service-cidr 10.245.0.0/16 \
  --cluster-dns 10.245.0.10 \
  --server https://10.42.1.10:6443 \
  --tls-san 10.42.1.20 \
  --tls-san 5.78.162.199

