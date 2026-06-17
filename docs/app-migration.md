# App Migration Plan

The old VM deployment model was:

```text
local build -> rsync selected files to /rk4/<app> -> remote docker compose build/up -> Traefik Docker labels
```

The k3s deployment model should be:

```text
build image -> push image to registry -> helm upgrade/install -> Traefik Ingress
```

## Shared Web App Path

The reusable chart at `k8s/charts/rk4-webapp` covers single-container HTTP apps:

- `ajt-web`, from `/home/gutswright/rk4/ajt/ajt-svelte`, port `3001`
- `momentum-web`, from `/home/gutswright/rk4/momentum/momentum-svelte`, port `3002`
- `portfolio-web`, from `/home/gutswright/rk4/portfolio/svelte`, port `3000`
- `rover-mfg-web`, from `/home/gutswright/rk4/rover-mfg/skeleton`, port `3003`

Each app has a values file under `k8s/apps/<app>/values.yaml`.

Before deploying, update each values file:

- set `ingress.hosts` to the real DNS names
- enable `ingress.tls` only after certificate handling is in place

Set the registry and image tag for local commands:

```sh
export RK4_REGISTRY=ghcr.io/YOUR_OWNER
export RK4_IMAGE_TAG=$(git rev-parse --short HEAD)
```

Build and push an app image:

```sh
just app-build portfolio-web
just app-push portfolio-web
```

Render one app locally:

```sh
just app-render portfolio-web
```

Deploy one app:

```sh
just app-deploy portfolio-web
```

Check app status:

```sh
just app-status
```

## Stateful Apps

These should not be pushed through the generic web-app chart:

- AJT Umami plus Postgres
- Obsidian CouchDB
- rk4-site Redis
- rk4-site FastAPI and SQLite volume
- rk4-site whiteboard MongoDB, storage backend, room backend, frontend

For these, create dedicated manifests or charts with explicit `PersistentVolumeClaim`
objects, `Secret` references, backups, and restore procedures.

## Traefik Mapping

Docker labels become Kubernetes `Ingress` objects:

- `traefik.http.routers.<name>.rule=Host(...)` becomes `spec.rules[].host`
- `traefik.http.services.<name>.loadbalancer.server.port=<port>` becomes a `Service`
  targeting the pod container port
- Docker networks are replaced by Kubernetes namespaces and Services
- `depends_on` is replaced by app readiness and service DNS

The cluster already has Traefik installed by k3s. Do not deploy the old
`control-center` Traefik container into the cluster.

## Image Registry

Kubernetes workers need to pull images from a registry. The repo currently uses
`RK4_REGISTRY` and `RK4_IMAGE_TAG` when rendering and deploying. If unset, the
commands default to placeholder `ghcr.io/OWNER` and `latest`.

If the registry is private, create an image pull secret in `rk4-apps` and add it
to each values file:

```yaml
imagePullSecrets:
  - name: ghcr
```

## TLS

The old Docker Traefik config used ACME certificate resolvers. The k3s Traefik
bootstrap currently configures placement and replicas, not ACME.

Use one of these before enabling TLS in app values:

- install `cert-manager` and issue TLS secrets referenced by each Ingress
- extend the k3s Traefik HelmChartConfig with ACME settings
- terminate TLS before the cluster and run HTTP from the load balancer to Traefik
