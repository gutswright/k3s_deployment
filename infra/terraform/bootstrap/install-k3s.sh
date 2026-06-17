#!/usr/bin/env bash
set -euo pipefail

SSH_USER="${SSH_USER:-guts}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/rk4_key}"
TOFU_BIN="${TOFU_BIN:-tofu}"

if [ -z "${K3S_TOKEN:-}" ]; then
  echo "Set K3S_TOKEN before running this script." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to read OpenTofu outputs." >&2
  exit 1
fi

cd "$(dirname "$0")/.."

outputs_json="$("$TOFU_BIN" output -json)"
main_server_public_ip="$(jq -r '.server_public_ips.value.main_server' <<<"$outputs_json")"
main_server_private_ip="$(jq -r '.server_private_ips.value.main_server' <<<"$outputs_json")"
server_2_public_ip="$(jq -r '.server_public_ips.value.server_2' <<<"$outputs_json")"
server_2_private_ip="$(jq -r '.server_private_ips.value.server_2' <<<"$outputs_json")"
server_3_public_ip="$(jq -r '.server_public_ips.value.server_3' <<<"$outputs_json")"
server_3_private_ip="$(jq -r '.server_private_ips.value.server_3' <<<"$outputs_json")"
load_balancer_private_ip="$(jq -r '.load_balancer_private_ipv4.value' <<<"$outputs_json")"

token_b64="$(printf '%s' "$K3S_TOKEN" | base64 | tr -d '\n')"
ssh_args=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  -o ServerAliveInterval=15
)

run_remote() {
  local host="$1"
  shift

  ssh "${ssh_args[@]}" "${SSH_USER}@${host}" "$@"
}

install_joining_server() {
  local node_name="$1"
  local public_ip="$2"
  local private_ip="$3"

  echo "Installing k3s server ${node_name} on ${public_ip}..."
  run_remote "$public_ip" \
    "sudo env NODE_NAME='$node_name' PRIVATE_IP='$private_ip' MAIN_SERVER_PRIVATE_IP='$main_server_private_ip' LB_PRIVATE_IP='$load_balancer_private_ip' K3S_TOKEN_B64='$token_b64' bash -s" <<'REMOTE'
set -euo pipefail

if systemctl is-active --quiet k3s; then
  echo "k3s server is already running."
  exit 0
fi

wait_for() {
  local description="$1"
  local attempts="$2"
  local delay_seconds="$3"
  shift 3

  for attempt in $(seq 1 "$attempts"); do
    echo "Waiting for $description, attempt $attempt/$attempts..."
    if "$@"; then
      return 0
    fi

    sleep "$delay_seconds"
  done

  echo "Timed out waiting for $description." >&2
  return 1
}

server_ready() {
  curl -ksS --connect-timeout 5 -o /dev/null "https://${MAIN_SERVER_PRIVATE_IP}:6443/readyz"
}

lb_ready() {
  curl -ksS --connect-timeout 5 -o /dev/null "https://${LB_PRIVATE_IP}:6443/readyz"
}

wait_for "k3s server at ${MAIN_SERVER_PRIVATE_IP}:6443" 180 10 server_ready
wait_for "k3s load balancer at ${LB_PRIVATE_IP}:6443" 60 5 lb_ready

K3S_TOKEN="$(printf '%s' "$K3S_TOKEN_B64" | base64 -d)"

install -d -m 0755 /etc/rancher/k3s
cat >/etc/rancher/k3s/config.yaml <<EOF
server: "https://${LB_PRIVATE_IP}:6443"
token: "$K3S_TOKEN"
node-name: "${NODE_NAME}"
node-ip: "${PRIVATE_IP}"
advertise-address: "${PRIVATE_IP}"
flannel-iface: "enp7s0"
cluster-cidr: "10.244.0.0/16"
service-cidr: "10.245.0.0/16"
cluster-dns: "10.245.0.10"
node-label:
  - "rk4.io/node-role=server"
  - "rk4.io/bootstrap=manual"
tls-san:
  - "rk4-k3s-main-server"
  - "rk4-k3s-server-2"
  - "rk4-k3s-server-3"
  - "kube.rk4.home"
  - "${LB_PRIVATE_IP}"
write-kubeconfig-mode: "0644"
EOF

curl -sfL https://get.k3s.io | sh -s - server
REMOTE
}

install_main_server() {
  echo "Installing k3s server rk4-k3s-main-server on ${main_server_public_ip}..."
  run_remote "$main_server_public_ip" \
    "sudo env PRIVATE_IP='$main_server_private_ip' LB_PRIVATE_IP='$load_balancer_private_ip' K3S_TOKEN_B64='$token_b64' bash -s" <<'REMOTE'
set -euo pipefail

if systemctl is-active --quiet k3s; then
  echo "k3s server is already running."
  exit 0
fi

K3S_TOKEN="$(printf '%s' "$K3S_TOKEN_B64" | base64 -d)"

install -d -m 0755 /etc/rancher/k3s
cat >/etc/rancher/k3s/config.yaml <<EOF
token: "$K3S_TOKEN"
node-name: "rk4-k3s-main-server"
node-ip: "${PRIVATE_IP}"
advertise-address: "${PRIVATE_IP}"
flannel-iface: "enp7s0"
cluster-cidr: "10.244.0.0/16"
service-cidr: "10.245.0.0/16"
cluster-dns: "10.245.0.10"
node-label:
  - "rk4.io/node-role=server"
  - "rk4.io/bootstrap=manual"
  - "rk4.io/workload-database=true"
  - "rk4.io/workload-analytics=true"
tls-san:
  - "rk4-k3s-main-server"
  - "rk4-k3s-server-2"
  - "rk4-k3s-server-3"
  - "kube.rk4.home"
  - "${PRIVATE_IP}"
  - "${LB_PRIVATE_IP}"
write-kubeconfig-mode: "0644"
EOF

curl -sfL https://get.k3s.io | sh -s - server --cluster-init
REMOTE
}

install_main_server
install_joining_server "rk4-k3s-server-2" "$server_2_public_ip" "$server_2_private_ip"
install_joining_server "rk4-k3s-server-3" "$server_3_public_ip" "$server_3_private_ip"
