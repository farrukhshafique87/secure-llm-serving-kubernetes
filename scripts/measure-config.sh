#!/usr/bin/env bash
# Measure one configuration: switch to it, then run the /chat and /health tests.
# Usage: measure-config.sh <config> <repetition>
# Configs: c0-baseline c1-rbac c2-netpol c3-mtls c4-tls c5-gateway c6-all
# Round-robin over configurations (interleaving), for example:
#   for r in 1 2 3; do for c in c0-baseline c1-rbac c2-netpol c3-mtls c4-tls c5-gateway c6-all; do
#     ./scripts/measure-config.sh "$c" "$r"; done; done
set -euo pipefail

CONFIG="${1:?usage: measure-config.sh <config> <repetition>}"
REP="${2:?usage: measure-config.sh <config> <repetition>}"
EXP="${EXP:-exp-06-final}"

cd "$(dirname "$0")/.."
# shellcheck source=lib/configs.sh
. scripts/lib/configs.sh
# shellcheck source=lib/run-lock.sh
. scripts/lib/run-lock.sh

run_lock
if run_recorded "$EXP" "$CONFIG" "$REP" && run_recorded "$EXP" "${CONFIG}-health" "$REP"; then
  echo "== SKIP $CONFIG r$REP: /chat and /health already recorded in results/$EXP"
  exit 0
fi

switch_config "$CONFIG"

export WARMUP="${WARMUP:-2m}"
./scripts/run-experiment.sh "$EXP" "$CONFIG" "$REP" "$NS"
RATE=50 DURATION=2m ./scripts/run-experiment.sh "$EXP" "${CONFIG}-health" "$REP" "$NS" tests/k6/health-path.js
