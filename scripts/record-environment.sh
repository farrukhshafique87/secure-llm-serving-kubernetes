#!/usr/bin/env bash
# Write an environment record next to experiment results (reproducibility).
# Usage: record-environment.sh <output-dir> <namespace>
set -euo pipefail
OUT="${1:?usage: record-environment.sh <output-dir> <namespace>}"
NS="${2:?usage: record-environment.sh <output-dir> <namespace>}"
mkdir -p "$OUT"
F="$OUT/environment.txt"

{
  echo "# Environment record - $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "## Host"
  uname -a
  echo "CPU cores: $(nproc)"
  free -h | head -2
  echo "## Tool versions"
  echo "platform=${PLATFORM:-kind}"
  # Docker and Kind exist only on the Kind host, not on the k6 VM (EXP-07).
  docker --version 2>&1 || true
  kind version 2>&1 || true
  kubectl version 2>&1 || true
  helm version --short
  k6 version 2>&1 || true
  echo "## Cluster"
  kubectl config current-context
  kubectl get nodes -o wide
  echo "## Namespace $NS: workloads, images, resources"
  kubectl -n "$NS" get deploy,svc,pvc,pods -o wide
  kubectl -n "$NS" get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" image="}{.spec.template.spec.containers[*].image}{" resources="}{.spec.template.spec.containers[*].resources}{"\n"}{end}'
  echo "## Model"
  kubectl -n "$NS" exec deploy/ollama -c ollama -- ollama list 2>&1 || true
  kubectl -n "$NS" exec deploy/ollama -c ollama -- ollama --version 2>&1 || true
  echo "## Controlled inference parameters"
  kubectl -n "$NS" get configmap fastapi-config -o jsonpath='{.data}'; echo
  echo "## Network policies / CNI"
  kubectl -n "$NS" get networkpolicy 2>&1 || true
  kubectl get pods -n calico-system 2>&1 | head -5 || true
  echo "calico version: $(kubectl get clusterinformation default -o jsonpath='{.spec.calicoVersion}' 2>&1 || true)"
  kubectl -n calico-system get ds calico-node -o jsonpath='calico-node image={.spec.template.spec.containers[0].image}{"\n"}' 2>&1 || true
  echo "## Ingress controller / gateway / metrics server"
  helm list -n traefik 2>&1 || true
  kubectl -n traefik get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" image="}{.spec.template.spec.containers[*].image}{"\n"}{end}' 2>&1 || true
  kubectl -n "$NS" get deploy gateway -o jsonpath='gateway image={.spec.template.spec.containers[0].image}{"\n"}' 2>&1 || true
  helm list -n linkerd 2>&1 || true
  kubectl -n linkerd get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" image="}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>&1 || true
  kubectl -n kube-system get deploy metrics-server -o jsonpath='metrics-server image={.spec.template.spec.containers[0].image}{"\n"}' 2>&1 || true
  kubectl -n "$NS" get ingress 2>&1 || true
  echo "## Git"
  git rev-parse HEAD 2>&1 || true
  git status --short 2>&1 | head -10 || true
} > "$F" 2>&1

echo "Wrote $F"
