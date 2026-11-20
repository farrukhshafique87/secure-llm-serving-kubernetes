#!/usr/bin/env bash
# Install the Traefik ingress controller. Re-runnable.
# Chart version is pinned (see below). Override: TRAEFIK_CHART_VERSION=<x.y.z>
# Values: kind/traefik-values.yaml; on a managed cloud (EXP-07)
#   TRAEFIK_VALUES=cloud/traefik-values.yaml
set -euo pipefail

cd "$(dirname "$0")/.."

helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null

# Pinned to the chart used in the EXP-06 runs (results/exp-06-final/*-environment.txt).
TRAEFIK_CHART_VERSION="${TRAEFIK_CHART_VERSION:-41.6.1}"
VERSION_ARGS=(--version "$TRAEFIK_CHART_VERSION")

helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  "${VERSION_ARGS[@]}" \
  -f "${TRAEFIK_VALUES:-kind/traefik-values.yaml}"

kubectl -n traefik rollout status deploy/traefik --timeout=180s

echo "== versions in use =="
helm list -n traefik
kubectl -n traefik get deploy traefik -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl get ingressclass
kubectl -n traefik get pods -o wide
