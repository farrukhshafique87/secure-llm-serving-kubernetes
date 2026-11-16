# Configuration table and switching, shared by measure-config.sh and measure-load.sh.
# Source from the repository root:  . scripts/lib/configs.sh
# shellcheck shell=bash

ALL_NS="llm-baseline llm-c1-rbac llm-c2-netpol llm-c3-mtls llm-c4-tls llm-c5-gateway llm-secure"

# config_vars <config>: sets OVERLAY, NS, URL and AUTH for a configuration.
config_vars() {
  case "$1" in
    c0-baseline) OVERLAY=kind-baseline;   NS=llm-baseline;   URL=http://localhost:8010;  AUTH=no  ;;
    c1-rbac)     OVERLAY=kind-c1-rbac;    NS=llm-c1-rbac;    URL=http://localhost:8010;  AUTH=no  ;;
    c2-netpol)   OVERLAY=kind-c2-netpol;  NS=llm-c2-netpol;  URL=http://localhost:8010;  AUTH=no  ;;
    c3-mtls)     OVERLAY=kind-c3-mtls;    NS=llm-c3-mtls;    URL=http://localhost:8010;  AUTH=no  ;;
    c4-tls)      OVERLAY=kind-c4-tls;     NS=llm-c4-tls;     URL=https://localhost:8443; AUTH=no  ;;
    c5-gateway)  OVERLAY=kind-c5-gateway; NS=llm-c5-gateway; URL=http://localhost:8010;  AUTH=yes ;;
    c6-all)      OVERLAY=kind-secure;     NS=llm-secure;     URL=https://localhost:8443; AUTH=yes ;;
    # EXP-04: c5-gateway with the gateway CPU limit at 1000 m (same namespace).
    c5-gateway-cpu1000) OVERLAY=kind-c5-gateway-cpu1000; NS=llm-c5-gateway; URL=http://localhost:8010; AUTH=yes ;;
    # EXP-03: 2 or 3 replicas of fastapi (c0) and of gateway and fastapi (c5, 1000 m).
    c0-baseline-r2) OVERLAY=kind-baseline-r2; NS=llm-baseline; URL=http://localhost:8010; AUTH=no ;;
    c0-baseline-r3) OVERLAY=kind-baseline-r3; NS=llm-baseline; URL=http://localhost:8010; AUTH=no ;;
    c5-gateway-cpu1000-r2) OVERLAY=kind-c5-gateway-cpu1000-r2; NS=llm-c5-gateway; URL=http://localhost:8010; AUTH=yes ;;
    c5-gateway-cpu1000-r3) OVERLAY=kind-c5-gateway-cpu1000-r3; NS=llm-c5-gateway; URL=http://localhost:8010; AUTH=yes ;;
    # EXP-03 HPA part: gateway and fastapi scaled by an HPA, 1 to 3 replicas.
    c5-gateway-cpu1000-hpa) OVERLAY=kind-c5-gateway-cpu1000-hpa; NS=llm-c5-gateway; URL=http://localhost:8010; AUTH=yes ;;
    *) echo "unknown config: $1" >&2; return 1 ;;
  esac
}

# overlay_meshed: true when the overlay of the current configuration injects
# the Linkerd proxy (c3-mtls and c6-all).
overlay_meshed() {
  kubectl kustomize "kubernetes/overlays/$OVERLAY" | grep -q 'linkerd.io/inject: enabled'
}

# mesh_cert_errors <namespace>...: prints one line per pod whose Linkerd proxy
# reported an expired certificate in the last MESH_LOG_WINDOW (default 2m) and
# returns 0 if it finds any. A broken mesh logs this error every second; a
# single line from the first second after a restart (old pods still shutting
# down) is not counted because it falls outside the window.
# Workload certificates are valid for 24 h and renewed by the proxy. If the
# host is suspended (laptop sleep) they can expire before the renewal runs,
# including the certificate of linkerd-identity itself. The mesh does not
# recover from that without restarting the pods.
mesh_cert_errors() {
  local ns pod line found=1
  for ns in "$@"; do
    for pod in $(kubectl -n "$ns" get pods -o name 2>/dev/null); do
      line="$(kubectl -n "$ns" logs "$pod" -c linkerd-proxy --since="${MESH_LOG_WINDOW:-2m}" 2>/dev/null \
        | grep -m1 'certificate expired' || true)"
      if [ -n "$line" ]; then
        echo "$ns/${pod#pod/}: ${line:0:200}"
        found=0
      fi
    done
  done
  return "$found"
}

# mesh_fail <reason>: prints why the switch stopped and how to recover.
mesh_fail() {
  {
    echo "ERROR: Linkerd mesh not healthy for $NS: $1"
    echo "No measurement was started. Recovery (certificates, model and volumes are kept):"
    echo "  kubectl -n linkerd rollout restart deploy"
    echo "  for d in \$(kubectl -n linkerd get deploy -o name); do kubectl -n linkerd rollout status \"\$d\" --timeout=180s; done"
    echo "  kubectl -n $NS rollout restart deploy"
    echo "  linkerd check --proxy -n $NS"
  } >&2
}

# check_mesh_running: for meshed configurations, stops before any rollout wait
# when proxies in the control plane or in this namespace report expired
# certificates. Otherwise the rollout would only time out after 300 s.
check_mesh_running() {
  overlay_meshed || return 0
  if ! command -v linkerd >/dev/null 2>&1; then
    echo "ERROR: linkerd CLI not found; it is needed to verify mTLS for $NS before measuring." >&2
    return 1
  fi
  if mesh_cert_errors linkerd "$NS" >&2; then
    mesh_fail "expired proxy certificates (lines above)"
    return 1
  fi
}

# check_mesh_ready: for meshed configurations, confirms after the rollout that
# every proxy in the namespace has a valid identity.
check_mesh_ready() {
  local log
  overlay_meshed || return 0
  log="$(mktemp)"
  if ! linkerd check --proxy -n "$NS" --wait 60s >"$log" 2>&1; then
    grep -E '×|error' "$log" | head -n 20 >&2 || true
    mesh_fail "linkerd check --proxy failed (full output: $log)"
    return 1
  fi
  rm -f "$log"
}

# switch_config <config>: pauses every other environment, starts this one,
# checks the Linkerd mesh for meshed configurations, makes sure the model is
# present and exports BASE_URL, AUTH_TOKEN and K6_INSECURE_SKIP_TLS_VERIFY for
# k6. Leaves NS set for the caller.
switch_config() {
  local config="$1" model="${OLLAMA_MODEL:-qwen2.5:0.5b}" n
  config_vars "$config"

  echo "== switching to $config ($NS)"
  for n in $ALL_NS; do
    if [ "$n" != "$NS" ] && kubectl get ns "$n" >/dev/null 2>&1; then
      ./scripts/pause-env.sh "$n" >/dev/null
    fi
  done

  check_mesh_running || return 1

  if ! ./scripts/resume-env.sh "kubernetes/overlays/$OVERLAY" "$NS"; then
    if overlay_meshed && mesh_cert_errors linkerd "$NS" >&2; then
      mesh_fail "rollout did not finish; proxies report expired certificates (lines above)"
    fi
    return 1
  fi

  check_mesh_ready || return 1

  if ! kubectl -n "$NS" exec deploy/ollama -c ollama -- ollama list | grep -q "$model"; then
    ./scripts/pull-model.sh "$NS" "kubernetes/overlays/$OVERLAY"
  fi

  unset AUTH_TOKEN K6_INSECURE_SKIP_TLS_VERIFY
  export BASE_URL="$URL"
  if [ "$AUTH" = "yes" ]; then
    AUTH_TOKEN="$(grep '^API_KEY=' kubernetes/components/gateway/gateway.env | cut -d= -f2)"
    export AUTH_TOKEN
  fi
  case "$URL" in https://*) export K6_INSECURE_SKIP_TLS_VERIFY=true ;; esac
}
