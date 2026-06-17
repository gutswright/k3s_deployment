# Setup

This repository separates infrastructure creation from k3s installation.
OpenTofu creates the Hetzner Cloud resources. The bootstrap script installs k3s
onto the servers after those resources exist.

## Prerequisites

Install these tools locally:

- `tofu`
- `hcloud`
- `jq`
- `ssh`
- `kubectl`

For app deploys, also install:

- `docker`
- `just`
- the app's build tools, for example `pnpm`

## Hetzner Credentials

Create `infra/terraform/terraform.tfvars` from the example:

```sh
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Set the Hetzner API token in that file:

```hcl
hcloud_token = "replace-with-a-hetzner-API-token"
```

Restrict SSH to your current public IP as a `/32`:

```hcl
ssh_allowed_cidrs = [
  "203.0.113.10/32"
]
```

The default SSH port is `22`. Change `ssh_port` only if you also intend to
connect with that port later.

## Create Infrastructure

Run OpenTofu from the repository root with the Justfile helpers:

```sh
just tf-init
just tf-fmt
just tf-validate
just tf-plan
just tf-apply
```

OpenTofu creates:

- three Ubuntu k3s server nodes
- one private Hetzner network
- one Hetzner Load Balancer
- firewall rules for SSH and private cluster traffic
- the SSH key registration

The state is local under `infra/terraform`. Keep it private and backed up.

## Install k3s

Set a shared k3s token before bootstrapping. Keep this value secret.

```sh
export K3S_TOKEN="replace-with-a-long-random-token"
```

Optional overrides:

```sh
export SSH_USER="guts"
export SSH_KEY_PATH="$HOME/.ssh/rk4_key"
export TOFU_BIN="tofu"
```

Install k3s:

```sh
./infra/terraform/bootstrap/install-k3s.sh
```

The script reads OpenTofu outputs, SSHes to each server, writes
`/etc/rancher/k3s/config.yaml`, and installs k3s. The main server starts the
embedded-etcd cluster with `--cluster-init`; the other two servers join through
the private load balancer at `10.42.1.20:6443`.

## kubectl Access

After k3s is installed, copy or merge the kubeconfig from a server. The API is
published through the Hetzner Load Balancer on port `6443`.

Useful checks:

```sh
tofu -chdir=infra/terraform output
kubectl get nodes -o wide
kubectl get pods -A
```

## App Deploys

The current app deployment pattern is manifest-based:

```text
build app -> docker build -> docker push to GHCR -> kubectl apply -> kubectl set image
```

See `deployment_example/portfolio/Justfile` and
`deployment_example/portfolio/portfolio-svelte.yaml` for the working example.
That flow expects a GitHub Container Registry token in
`GITHUB_K3S_REGISTRY_TOKEN`.
