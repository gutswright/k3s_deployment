# rk4-k3s Architecture

This repository builds a small HA k3s cluster on Hetzner Cloud in `hil`.

## Infrastructure

OpenTofu owns the cloud resources:

- `rk4-k3s-main-server`: CPX11, k3s server node, `10.42.1.10`
- `rk4-k3s-server-2`: CPX11, k3s server node, `10.42.1.12`
- `rk4-k3s-server-3`: CPX11, k3s server node, `10.42.1.13`
- `rk4-k3s-lb-1`: LB11, public entry point and private API load balancer,
  `10.42.1.20` on the private network
- `rk4-k3s-net`: private Hetzner Cloud network, `10.42.0.0/16`

All three nodes are k3s servers. There are no dedicated worker nodes in the
current design.

## Traffic Model

Public web traffic:

```text
Internet
-> Hetzner LB11 public IP on 80/443
-> k3s server nodes over the private network
-> Traefik
-> Kubernetes Services
-> Pods
```

Kubernetes API traffic:

```text
kubectl or joining server
-> Hetzner LB11 on 6443
-> k3s server nodes over the private network
```

The load balancer targets all three server nodes using private IPs.

## k3s Bootstrap

Terraform does not install k3s. It only prepares the nodes with cloud-init:

- creates the `guts` sudo user
- configures SSH
- installs `ca-certificates` and `curl`
- configures the Hetzner private network route

`infra/terraform/bootstrap/install-k3s.sh` performs the k3s installation over
SSH. It reads `tofu output -json`, installs the first server with
`--cluster-init`, then joins the other two servers through
`https://10.42.1.20:6443`.

The cluster uses:

- pod CIDR: `10.244.0.0/16`
- service CIDR: `10.245.0.0/16`
- cluster DNS: `10.245.0.10`
- flannel interface: `enp7s0`
- embedded etcd

## Application Boundary

Applications are deployed with Kubernetes manifests and image updates, not with
Terraform.

The current deploy loop is:

```text
app source
-> app build
-> Docker image
-> GHCR
-> Kubernetes Deployment, Service, Ingress
-> Traefik
```

The portfolio example in `deployment_example/portfolio` is the reference for
this pattern. App manifests define the namespace, image pull secret, service,
Ingress, Traefik middleware, and cert-manager issuer as needed.

## OpenTofu Boundary

OpenTofu owns:

- servers
- private network and subnet
- firewall
- load balancer
- SSH key registration

OpenTofu does not own:

- k3s installation
- Kubernetes workloads
- app images
- certificates
- app databases or persistent volumes
- backup and restore procedures
