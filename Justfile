set dotenv-load := false

tofu-dir := "infra/terraform"
apps-namespace := "rk4-apps"
webapp-chart := "k8s/charts/rk4-webapp"

default:
    just --list

deploy:
    @echo "Usage: just app-deploy <app-name>"
    @echo "Example: just app-deploy portfolio-web"

tf-init:
    tofu -chdir={{tofu-dir}} init

tf-fmt:
    tofu -chdir={{tofu-dir}} fmt -recursive

tf-validate:
    tofu -chdir={{tofu-dir}} validate

tf-plan:
    tofu -chdir={{tofu-dir}} plan

tf-apply:
    tofu -chdir={{tofu-dir}} apply

k8s-namespace:
    kubectl apply -f k8s/apps/namespace.yaml

app-render app:
    @registry="${RK4_REGISTRY:-ghcr.io/OWNER}"; tag="${RK4_IMAGE_TAG:-latest}"; helm template {{app}} {{webapp-chart}} \
        --namespace {{apps-namespace}} \
        --values k8s/apps/{{app}}/values.yaml \
        --set image.repository="$registry/{{app}}" \
        --set image.tag="$tag"

app-deploy app: k8s-namespace
    @registry="${RK4_REGISTRY:-ghcr.io/OWNER}"; tag="${RK4_IMAGE_TAG:-latest}"; helm upgrade --install {{app}} {{webapp-chart}} \
        --namespace {{apps-namespace}} \
        --values k8s/apps/{{app}}/values.yaml \
        --set image.repository="$registry/{{app}}" \
        --set image.tag="$tag"

app-build app:
    ./scripts/build-app-image.sh build {{app}}

app-push app:
    ./scripts/build-app-image.sh push {{app}}

app-status:
    kubectl get deploy,svc,ingress,pods -n {{apps-namespace}}
