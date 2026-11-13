#!/usr/bin/env bash
# Create the Kind cluster, install Calico, label nodes. Safe to re-run.
set -euo pipefail

CLUSTER="thesis-cluster"
CALICO_VERSION="${CALICO_VERSION:-v3.32.2}"   # pinned: calico-node v3.32.2 verified on the running cluster (2026-10-15)

cd "$(dirname "$0")/.."

if kind get clusters | grep -qx "$CLUSTER"; then
  echo "Cluster $CLUSTER already exists - skipping creation"
else
  kind create cluster --config kind/kind-cluster.yaml
fi

kubectl config use-context "kind-$CLUSTER"

if ! kubectl get ns calico-system >/dev/null 2>&1; then
  kubectl apply --server-side --force-conflicts -f \
    "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
  # The CRD appears a moment after the apply; wait on a missing CRD fails at once.
  until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do sleep 2; done
  kubectl wait --for=condition=established crd/installations.operator.tigera.io --timeout=90s
  kubectl apply -f kind/calico-installation.yaml
fi

echo "Waiting for Calico and nodes (can take 2-4 min)..."
until kubectl get ns calico-system >/dev/null 2>&1; do sleep 5; done
kubectl -n calico-system rollout status ds/calico-node --timeout=300s
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Fixed placement (see kubernetes/components/kind-placement)
kubectl label node "${CLUSTER}-worker" role=inference --overwrite
kubectl label node "${CLUSTER}-worker2" role=api --overwrite

kubectl get nodes -L role
