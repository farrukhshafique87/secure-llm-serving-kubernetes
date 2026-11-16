#!/usr/bin/env bash
# Start an environment again. Usage: resume-env.sh <overlay-dir> <namespace>
# Re-applies the overlay (restores Ingress, NodePort and the replica counts of
# the overlay) and waits for the pods.
set -euo pipefail
OVERLAY="${1:?usage: resume-env.sh <overlay-dir> <namespace>}"
NS="${2:?usage: resume-env.sh <overlay-dir> <namespace>}"

# A NodePort can only be used by one service in the whole cluster. If another
# (paused) environment still holds a port this overlay needs, apply would fail
# halfway. Stop before changing anything instead.
for port in $(kubectl kustomize "$OVERLAY" | awk '/nodePort:/ {print $2}'); do
  holder=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type=="NodePort")]}{.metadata.namespace}{" "}{.spec.ports[*].nodePort}{"\n"}{end}' \
    | awk -v p="$port" -v ns="$NS" '$1 != ns { for (i = 2; i <= NF; i++) if ($i == p) print $1 }')
  if [ -n "$holder" ]; then
    echo "ERROR: NodePort $port is already used in namespace(s): $holder"
    echo "Pause that environment first: ./scripts/pause-env.sh <namespace>"
    exit 1
  fi
done

# "<deployment> <replicas>" for every Deployment in the overlay (1 if not set).
# pause-env.sh scaled them to 0, and kubectl apply leaves a field alone when its
# value in the manifest did not change, so the replicas are set explicitly.
DEPLOYMENTS="$(kubectl kustomize "$OVERLAY" | awk '
  function flush() {
    if (kind == "Deployment" && name != "") print name, (rep == "" ? 1 : rep)
    kind = name = rep = sec = ""
  }
  /^---/ { flush(); next }
  /^[A-Za-z]/ { sec = $1 }
  /^kind: / { kind = $2 }
  sec == "metadata:" && /^  name: / && name == "" { name = $2 }
  sec == "spec:" && /^  replicas: / { rep = $2 }
  END { flush() }')"

kubectl apply -k "$OVERLAY"
# Configurations that share a namespace differ in their autoscalers (EXP-03):
# apply does not delete an HPA that the overlay no longer contains.
if ! kubectl kustomize "$OVERLAY" | grep -q '^kind: HorizontalPodAutoscaler'; then
  kubectl -n "$NS" delete hpa --all --ignore-not-found
fi
while read -r name replicas; do
  kubectl -n "$NS" scale deploy "$name" --replicas="$replicas"
done <<<"$DEPLOYMENTS"
while read -r name _; do
  kubectl -n "$NS" rollout status "deploy/$name" --timeout=300s
done <<<"$DEPLOYMENTS"
