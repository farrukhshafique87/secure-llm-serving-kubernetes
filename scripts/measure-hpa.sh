#!/usr/bin/env bash
# EXP-03 HPA part: one load-step run (tests/k6/health-step.js) for one
# configuration and one repetition. Waits until gateway and fastapi are back at
# the replica count of the overlay, so that every run starts from the same
# state, and records the replica counts every 5 s during the run.
#
# Usage: measure-hpa.sh <config> <repetition>
#
# Env overrides:
#   EXP        result folder under results/ (default exp-03-hpa)
#
# Result names: <config>-step-r<N>.json, .meta.txt, .resources.txt,
# .replicas.txt ("<UTC time> <deployment>=<ready>/<desired> ...") and, for
# a configuration with an HPA, .hpa.txt (its state and scaling events).
set -euo pipefail

CONFIG="${1:?usage: measure-hpa.sh <config> <repetition>}"
REP="${2:?usage: measure-hpa.sh <config> <repetition>}"
export EXP="${EXP:-exp-03-hpa}"

cd "$(dirname "$0")/.."
# shellcheck source=lib/configs.sh
. scripts/lib/configs.sh
# shellcheck source=lib/run-lock.sh
. scripts/lib/run-lock.sh

run_lock
if run_recorded "$EXP" "${CONFIG}-step" "$REP"; then
  echo "== SKIP $EXP ${CONFIG}-step-r${REP}: already recorded"
  exit 0
fi
switch_config "$CONFIG"

OUT="results/$EXP"
mkdir -p "$OUT"
DEPLOYS="gateway fastapi"

replicas() {
  local d
  for d in $DEPLOYS; do
    printf ' %s=%s/%s' "$d" \
      "$(kubectl -n "$NS" get deploy "$d" -o jsonpath='{.status.readyReplicas}')" \
      "$(kubectl -n "$NS" get deploy "$d" -o jsonpath='{.spec.replicas}')"
  done
}

# The previous run ends at the low rate, but the HPA needs its scale-down
# window to return to the minimum. Wait for it (at most 5 min).
# Replica count of gateway in the overlay (the same for fastapi in every
# configuration of this part; 1 if not set).
WANT="$(kubectl kustomize "kubernetes/overlays/$OVERLAY" | awk '
  /^---/ { kind = name = "" }
  /^kind: / { kind = $2 }
  /^  name: / && name == "" { name = $2 }
  kind == "Deployment" && name == "gateway" && /^  replicas: / { print $2; exit }')"
WANT="${WANT:-1}"
for _ in $(seq 60); do
  NOW="$(replicas)"
  [ "$NOW" = "$(for d in $DEPLOYS; do printf ' %s=%s/%s' "$d" "$WANT" "$WANT"; done)" ] && break
  sleep 5
done
echo "== replicas at start:$NOW"

# The sampler closes the lock descriptor, so that its last sleep does not
# hold the measurement lock after this script ends.
( exec 9>&-; while true; do echo "$(date -u +%H:%M:%S)$(replicas)"; sleep 5; done ) \
  > "$OUT/${CONFIG}-step-r${REP}.replicas.txt" &
SAMPLER=$!
trap 'kill "$SAMPLER" 2>/dev/null || true' EXIT

# Warm-up at the low rate of the step, so that it does not start a scale-out.
# DURATION only labels the meta file; the step script has a fixed profile.
WARMUP_SCRIPT=tests/k6/health-path.js RATE=20 WARMUP=30s DURATION=12m20s \
  COOLDOWN=120 PRE_VUS=110 MAX_VUS=250 \
  ./scripts/run-experiment.sh "$EXP" "${CONFIG}-step" "$REP" "$NS" tests/k6/health-step.js

# Scaling decisions of the HPA (if the configuration has one), for the record.
if kubectl -n "$NS" get hpa -o name 2>/dev/null | grep -q .; then
  {
    kubectl -n "$NS" get hpa
    kubectl -n "$NS" get events --field-selector involvedObject.kind=HorizontalPodAutoscaler \
      --sort-by=.lastTimestamp
  } > "$OUT/${CONFIG}-step-r${REP}.hpa.txt"
fi
