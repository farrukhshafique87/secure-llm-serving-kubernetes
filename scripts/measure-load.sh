#!/usr/bin/env bash
# EXP-02 load sweep for one configuration and one repetition.
# Switches to the configuration once, then runs every load level on the chosen
# paths, lowest level first, with a cool-down after each run.
#
# Usage: measure-load.sh <config> <repetition>
#
# Env overrides:
#   PATHS      paths to measure: "health", "chat" or "health chat" (default)
#   RATES      /health request rates in req/s      (default "50 60 70 80 90 100")
#   VUS_LIST   /chat virtual users                 (default "1 2 4")
#   EXP        result folder under results/        (default exp-02-load)
#
# Interleave repetitions over configurations, for example:
#   for r in 1 2 3; do for c in c0-baseline c5-gateway c6-all; do
#     PATHS=health ./scripts/measure-load.sh "$c" "$r"; done; done
#
# Result names: <config>-health-rate<R>-r<N>.json and <config>-chat-vus<V>-r<N>.json
set -euo pipefail

CONFIG="${1:?usage: measure-load.sh <config> <repetition>}"
REP="${2:?usage: measure-load.sh <config> <repetition>}"
PATHS="${PATHS:-health chat}"
RATES="${RATES:-50 60 70 80 90 100}"
VUS_LIST="${VUS_LIST:-1 2 4}"
export EXP="${EXP:-exp-02-load}"

cd "$(dirname "$0")/.."
# shellcheck source=lib/configs.sh
. scripts/lib/configs.sh
# shellcheck source=lib/run-lock.sh
. scripts/lib/run-lock.sh

run_lock
switch_config "$CONFIG"

for path in $PATHS; do
  case "$path" in
    health)
      for rate in $RATES; do
        # Enough VUs that k6 itself never limits the arrival rate below
        # about 1 s latency; if it still runs out, dropped_iterations shows it.
        RATE="$rate" DURATION=2m WARMUP=30s COOLDOWN=60 \
          PRE_VUS=$((rate / 2 + 10)) MAX_VUS=$((rate + 50)) \
          ./scripts/run-experiment.sh "$EXP" "${CONFIG}-health-rate${rate}" "$REP" "$NS" \
          tests/k6/health-path.js
      done
      ;;
    chat)
      for vus in $VUS_LIST; do
        VUS="$vus" DURATION=3m WARMUP=1m COOLDOWN=120 \
          ./scripts/run-experiment.sh "$EXP" "${CONFIG}-chat-vus${vus}" "$REP" "$NS"
      done
      ;;
    *) echo "unknown path: $path (use health or chat)" >&2; exit 1 ;;
  esac
done
