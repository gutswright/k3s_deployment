# rk4-k3s Architecture

This repository builds a small learning k3s cluster on Hetzner Cloud in `hil`.

## Phase 1 infrastructure

- `rk4-k3s-server-1`: CPX21, single k3s server/control-plane node.
- `rk4-k3s-worker-1`: CPX11, k3s worker node.
- `rk4-k3s-worker-2`: CPX11, k3s worker node.
- `rk4-k3s-lb-1`: LB11, public HTTP/HTTPS entry point.
- `rk4-k3s-net`: private Hetzner Cloud network.

Traffic model:

```text
Internet
-> Hetzner LB11 public IP
-> CPX11 workers over the private network
-> Traefik
-> k3s Services
-> Pods
```

The control plane is intentionally not highly available. The CPX21 is a single
point of failure for Kubernetes API availability and scheduling.

## OpenTofu boundary

OpenTofu owns cloud infrastructure only:

- servers
- private network
- firewall
- load balancer
- SSH key registration

k3s installation, Kubernetes resources, apps, databases, backups, and logging
will be managed by bootstrap scripts, Helm, or manifests in later phases.
