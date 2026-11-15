# One measurement at a time, shared by measure-config.sh, measure-load.sh and
# run-experiment.sh. Source from the repository root:  . scripts/lib/run-lock.sh
# shellcheck shell=bash

# run_lock: takes the measurement lock for this process and its children. A
# second measurement started while one runs waits until the first one ends;
# nested scripts (measure-config.sh -> run-experiment.sh) reuse the lock.
run_lock() {
  local lock="${RUN_LOCK_FILE:-/tmp/thesis-measurement.lock}"
  [ "${RUN_LOCK_HELD:-}" = "1" ] && return 0
  if ! command -v flock >/dev/null 2>&1; then
    echo "ERROR: flock not found (package util-linux); it keeps two measurements from overlapping." >&2
    return 1
  fi
  exec 9>"$lock"
  if ! flock -n 9; then
    echo "== another measurement is running; waiting until it ends ($(date -Is))"
    flock 9
    echo "== lock free, continuing ($(date -Is))"
  fi
  export RUN_LOCK_HELD=1
}

# run_recorded <exp> <config> <rep>: true when results/<exp> already holds a
# summary or meta file for this run. Such a run is not measured again; delete
# its files to repeat it.
run_recorded() {
  local f
  for f in "results/$1/$2-r$3.json" "results/$1/$2-r$3.meta.txt"; do
    [ -e "$f" ] && return 0
  done
  return 1
}
