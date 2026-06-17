# Verification Commands

Most commands in this document are read-only. Commands that change state are
called out separately.

## OpenTofu / Hetzner

Run from the repository root:

```sh
just tf-plan
tofu -chdir=infra/terraform output
hcloud server list
hcloud load-balancer list
```

Expected when infrastructure is stable:

```text
No changes.
```

Current private addresses from the Terraform config:

```text
rk4-k3s-main-server   10.42.1.10
rk4-k3s-server-2      10.42.1.12
rk4-k3s-server-3      10.42.1.13
rk4-k3s-lb-1          10.42.1.20
```

Use `tofu output` for public IPs instead of hard-coding them.

## SSH Access

Use the current public IPs from `tofu output`.

```sh
ssh -i ~/.ssh/rk4_key guts@SERVER_PUBLIC_IP
```

If `ssh_port` was changed in `terraform.tfvars`, include the matching port:

```sh
ssh -i ~/.ssh/rk4_key -p SSH_PORT guts@SERVER_PUBLIC_IP
```

If a server was intentionally rebuilt and SSH warns that the host key changed:

```sh
ssh-keygen -R SERVER_PUBLIC_IP
```

## Cloud-init

Run on each node:

```sh
cloud-init status --long
```

Expected:

```text
status: done
extended_status: done
errors: []
```

If cloud-init failed:

```sh
sudo tail -n 200 /var/log/cloud-init-output.log
```

For live progress while a node is booting:

```sh
sudo tail -f /var/log/cloud-init-output.log
```

## Node Networking

Run on each node:

```sh
ip -4 addr show enp7s0
ip route
```

Expected Hetzner private route:

```text
10.42.0.0/16 via 10.42.0.1 dev enp7s0 ... onlink
```

Expected k3s pod routes use `10.244.x.x`, not `10.42.x.x`.

From any server, verify the private network:

```sh
ping -c 3 10.42.1.10
ping -c 3 10.42.1.12
ping -c 3 10.42.1.13
ping -c 3 10.42.1.20
```

## k3s Services

All nodes are k3s servers in the current design.

Run on each node:

```sh
systemctl status k3s --no-pager -l
journalctl -u k3s --no-pager -n 150
```

Check API readiness through each path:

```sh
curl -k https://10.42.1.10:6443/readyz
curl -k https://10.42.1.12:6443/readyz
curl -k https://10.42.1.13:6443/readyz
curl -k https://10.42.1.20:6443/readyz
```

An HTTP `401` still proves the API server is reachable. A timeout or connection
refused means the network path or k3s service needs investigation.

## Kubernetes Health

Run with a kubeconfig that points at the cluster:

```sh
kubectl get nodes -o wide
kubectl get nodes --show-labels
kubectl get pods -A -o wide
kubectl get --raw='/readyz?verbose'
```

Expected nodes:

```text
rk4-k3s-main-server   Ready
rk4-k3s-server-2      Ready
rk4-k3s-server-3      Ready
```

Check pod CIDRs:

```sh
kubectl describe node rk4-k3s-main-server | grep -i podcidr -A2
kubectl describe node rk4-k3s-server-2 | grep -i podcidr -A2
kubectl describe node rk4-k3s-server-3 | grep -i podcidr -A2
```

Pod CIDRs should be under `10.244.x.0/24`.

Check the local k3s CLI from a server:

```sh
sudo k3s kubectl get nodes
sudo k3s kubectl get --raw='/readyz?verbose'
```

## Traefik / Ingress

Run with kubectl:

```sh
kubectl get pods -n kube-system -o wide | grep traefik
kubectl get svc -n kube-system traefik
kubectl get ingress -A
```

Test Traefik through each node and through the load balancer:

```sh
curl -I http://10.42.1.10
curl -I http://10.42.1.12
curl -I http://10.42.1.13
curl -I http://LOAD_BALANCER_PUBLIC_IPV4
```

A `404 Not Found` from Traefik is acceptable when no matching Ingress route
exists. It means the request reached Traefik.

## App Deployment

For the portfolio-style deployment:

```sh
cd deployment_example/portfolio
just status
just image
kubectl -n my-k3s get deploy,svc,ingress,pods -l app=portfolio-svelte -o wide
kubectl -n my-k3s rollout status deployment/portfolio-svelte
```

Check image pull secret presence:

```sh
kubectl -n my-k3s get secret github_api_key
```

Check Ingress and TLS state:

```sh
kubectl -n my-k3s describe ingress portfolio-svelte
kubectl -n my-k3s get certificate
kubectl describe clusterissuer letsencrypt-prod
```

## Mutating Commands

These commands change state.

Rebuild all three servers through Terraform:

```sh
./infra/terraform/bootstrap/rebuild_script.sh
```

Reinstall k3s after infrastructure exists:

```sh
export K3S_TOKEN="replace-with-the-cluster-token"
./infra/terraform/bootstrap/install-k3s.sh
```

Redeploy the portfolio example:

```sh
cd deployment_example/portfolio
export GITHUB_K3S_REGISTRY_TOKEN="..."
just deploy
```

Restart the portfolio Deployment without building a new image:

```sh
cd deployment_example/portfolio
just restart
```

## Historical Commands

These commands were used during earlier investigation or recovery. They are not
the desired steady-state workflow.

Temporary private route experiments:

```sh
ip route del 10.42.0.0/16 || true
ip route add 10.42.0.0/16 via 10.42.0.1 dev enp7s0 onlink
```

This is now encoded in `base-cloud-init.yaml.tftpl`.

Manual SSH repair:

```sh
mkdir -p /run/sshd
sshd -t
systemctl restart ssh
```

This is now encoded in cloud-init.

Manual k3s install snippets in `infra/terraform/install_scripts` are historical
references. The preferred install path is
`infra/terraform/bootstrap/install-k3s.sh`.
