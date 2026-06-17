# App Deployment

The old VM deployment model was:

```text
local build -> rsync files to /rk4/<app> -> remote docker compose build/up -> Traefik Docker labels
```

The current k3s deployment model is:

```text
local app build -> docker build -> docker push to GHCR -> kubectl apply -> kubectl set image
```

The reference implementation is `deployment_example/portfolio`.

## Portfolio Example

The example contains:

- `deployment_example/portfolio/Justfile`
- `deployment_example/portfolio/portfolio-svelte.yaml`

The Justfile builds the Svelte app, builds and pushes a Docker image, applies
the Kubernetes manifest, updates the Deployment image to the new tag, and waits
for rollout.

Before using the example for a real app, update these values:

- `registry_user`
- `image_repo`
- `namespace`
- `deployment`
- `container`
- `manifest`
- `pull_secret`
- Ingress host names
- cert-manager email

## Registry Token

The deploy flow expects a GitHub Container Registry token:

```sh
export GITHUB_K3S_REGISTRY_TOKEN="..."
```

The Justfile logs Docker into `ghcr.io` and creates or updates the Kubernetes
image pull secret:

```sh
kubectl -n my-k3s create secret docker-registry github_api_key \
  --docker-server=ghcr.io \
  --docker-username=github_username \
  --docker-password="$GITHUB_K3S_REGISTRY_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Do not commit the token or a rendered secret.

## Deploy Commands

Run from the app deployment directory:

```sh
cd deployment_example/portfolio
just deploy
```

Useful operational commands:

```sh
just status
just image
just restart
```

The deploy target performs these steps:

```text
require token
-> build app dependencies and production bundle
-> docker login
-> create or update image pull secret
-> docker build
-> docker push immutable timestamp tag
-> docker push latest
-> kubectl apply manifest
-> kubectl set image deployment/<name> <container>=<image>:<tag>
-> kubectl rollout status
```

## Kubernetes Manifest Pattern

Each single-container web app should define:

- `Deployment`
- `Service`
- `Ingress`
- optional Traefik `Middleware`
- optional cert-manager `ClusterIssuer` or issuer reference

The Deployment should include:

- explicit namespace
- app labels shared by Deployment, Service, and Ingress
- `imagePullSecrets` when using a private GHCR image
- named container port
- readiness and liveness probes

The Service should be `ClusterIP`. The Ingress routes public traffic from
Traefik to that Service.

## Traefik Mapping

Docker labels become Kubernetes resources:

- `traefik.http.routers.<name>.rule=Host(...)` becomes `spec.rules[].host`
- `traefik.http.services.<name>.loadbalancer.server.port=<port>` becomes a
  Service targeting the container port
- Docker networks become Kubernetes namespaces and Services
- `depends_on` becomes readiness probes and service DNS

Do not deploy the old Docker Traefik container into the cluster. k3s provides
Traefik inside Kubernetes.

## TLS

The portfolio example uses cert-manager annotations and a `ClusterIssuer` with
HTTP-01 through Traefik.

Before enabling TLS for an app:

- point DNS at the Hetzner Load Balancer public IPv4
- make sure cert-manager is installed in the cluster
- set the real host under `spec.tls[].hosts` and `spec.rules[].host`
- set a real ACME email address

## Stateful Apps

Do not force stateful services through the simple web-app pattern. Apps with
databases or durable storage need dedicated manifests or charts with:

- `PersistentVolumeClaim` objects
- `Secret` references
- backup jobs
- restore procedures
- explicit upgrade notes
