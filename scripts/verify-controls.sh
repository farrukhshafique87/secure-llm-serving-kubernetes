#!/usr/bin/env bash
# Functional checks of the security controls in one namespace.
# Usage: verify-controls.sh <namespace> [entry-url]
# Checks only what is deployed in the namespace (RBAC objects, NetworkPolicies,
# mesh, ingress TLS, gateway). The TLS and gateway checks send requests to the
# entry URL from outside the cluster, as a client would; without a URL they are
# skipped. Exit code 1 if any check fails, 2 if the pods never become Ready.
# A failing check prints the last lines of the command output, so the cause is
# recorded (a check that hides its error cannot be explained afterwards).
set -uo pipefail
cd "$(dirname "$0")/.."
NS="${1:?usage: verify-controls.sh <namespace> [entry-url]}"
URL="${2:-}"
PASS=0
FAIL=0

# check "<description>" <yes|no> <command...>   (yes = command must succeed)
check() {
  local desc="$1" expected="$2" result out
  shift 2
  if out=$("$@" 2>&1); then result=yes; else result=no; fi
  if [ "$result" = "$expected" ]; then
    echo "PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $desc (expected $expected, got $result)"
    printf '%s\n' "$out" | tail -n 5 | sed 's/^/      | /'
    FAIL=$((FAIL + 1))
  fi
}

# HTTP GET from inside a pod: fetch <deployment> <url>
fetch() {
  kubectl -n "$NS" exec "deploy/$1" -c "$1" -- python -c \
    "import sys, urllib.request; urllib.request.urlopen(sys.argv[1], timeout=4)" "$2"
}

# Checks right after a rollout can fail only because a pod is not Ready yet.
echo "Waiting for all pods in $NS to be Ready..."
if ! kubectl -n "$NS" wait --for=condition=Ready pod --all --timeout=180s >/dev/null; then
  echo "ERROR: pods in $NS are not Ready; no checks were run."
  kubectl -n "$NS" get pods
  exit 2
fi

token_not_mounted() {
  [ "$(kubectl -n "$NS" get deploy "$1" -o jsonpath='{.spec.template.spec.automountServiceAccountToken}')" = "false" ]
}

if kubectl -n "$NS" get serviceaccount fastapi >/dev/null 2>&1; then
  echo "== RBAC"
  check "fastapi pod has no API token mounted" yes token_not_mounted fastapi
  check "fastapi service account cannot list pods" no \
    kubectl auth can-i list pods -n "$NS" --as="system:serviceaccount:$NS:fastapi"
  check "viewer group can read pods" yes \
    kubectl auth can-i get pods -n "$NS" --as=tester --as-group=llm-viewers
  check "viewer group cannot read secrets" no \
    kubectl auth can-i get secrets -n "$NS" --as=tester --as-group=llm-viewers
  check "viewer group cannot delete deployments" no \
    kubectl auth can-i delete deployments.apps -n "$NS" --as=tester --as-group=llm-viewers
fi

if kubectl -n "$NS" get networkpolicy -o name 2>/dev/null | grep -q .; then
  echo "== NetworkPolicies"
  check "api -> ollama is allowed" yes fetch fastapi http://ollama-service:11434/api/tags
  check "api -> internet is blocked" no fetch fastapi https://example.com
  if kubectl -n "$NS" get deploy gateway >/dev/null 2>&1; then
    check "gateway -> api is allowed" yes fetch gateway http://fastapi-service:8010/health
    check "gateway -> ollama is blocked" no fetch gateway http://ollama-service:11434/api/tags
  fi
fi

has_proxy() {
  local names
  names=$(kubectl -n "$NS" get pods -l "$1" \
    -o jsonpath='{.items[0].spec.containers[*].name} {.items[0].spec.initContainers[*].name}')
  [[ "$names" == *linkerd-proxy* ]]
}

tls_seen() {
  local metrics
  metrics=$(kubectl -n "$NS" exec deploy/fastapi -c fastapi -- curl -s localhost:4191/metrics)
  [[ "$metrics" == *'tls="true"'* ]]
}

mesh_enabled() {
  [ "$(kubectl -n "$NS" get deploy fastapi -o jsonpath='{.spec.template.metadata.annotations.linkerd\.io/inject}')" = "enabled" ]
}

if mesh_enabled; then
  echo "== mTLS (Linkerd)"
  check "api pod runs the Linkerd proxy" yes has_proxy app.kubernetes.io/name=llm-api
  check "ollama pod runs the Linkerd proxy" yes has_proxy app=ollama
  fetch fastapi http://ollama-service:11434/api/tags >/dev/null 2>&1
  check "api -> ollama traffic is mTLS (proxy metrics)" yes tls_seen
fi

# HTTP status code of a request from the host; prints it so a failure shows it.
status_is() {
  local want="$1" got
  shift
  got=$(curl -sk --max-time 5 -o /dev/null -w '%{http_code}' "$@")
  echo "HTTP $got"
  [ "$got" = "$want" ]
}

AUTH_ARGS=()
if [ -n "$URL" ] && kubectl -n "$NS" get deploy gateway >/dev/null 2>&1; then
  echo "== API gateway"
  # The key goes to curl through a private header file, never on the command line.
  HDR=$(mktemp)
  trap 'rm -f "$HDR"' EXIT
  chmod 600 "$HDR"
  echo "Authorization: Bearer $(grep '^API_KEY=' kubernetes/components/gateway/gateway.env | cut -d= -f2)" > "$HDR"
  AUTH_ARGS=(-H "@$HDR")
  check "request without key is rejected (401)" yes status_is 401 "$URL/health"
  check "request with a wrong key is rejected (401)" yes status_is 401 -H "Authorization: Bearer wrong-key" "$URL/health"
  check "request with the key is accepted (200)" yes status_is 200 "${AUTH_ARGS[@]}" "$URL/health"
  check "/metrics is blocked even with the key (404)" yes status_is 404 "${AUTH_ARGS[@]}" "$URL/metrics"
  check "/docs is blocked even with the key (404)" yes status_is 404 "${AUTH_ARGS[@]}" "$URL/docs"
fi

served_cert_is_lab_cert() {
  local served expected
  served=$(openssl s_client -connect "$1" -servername "${1%:*}" </dev/null 2>/dev/null \
    | openssl x509 -noout -fingerprint -sha256)
  expected=$(openssl x509 -in kubernetes/components/ingress-tls/tls.crt -noout -fingerprint -sha256)
  echo "served: ${served:-none}"
  [ -n "$served" ] && [ "$served" = "$expected" ]
}

if [[ "$URL" == https://* ]] && kubectl -n "$NS" get ingress -o name 2>/dev/null | grep -q .; then
  echo "== TLS at the ingress"
  HOSTPORT="${URL#https://}"
  check "entry presents the lab certificate" yes served_cert_is_lab_cert "$HOSTPORT"
  check "HTTPS request reaches the service (200)" yes status_is 200 "${AUTH_ARGS[@]}" "$URL/health"
  check "plain HTTP on the TLS port is not served (no 200)" no status_is 200 "${AUTH_ARGS[@]}" "http://$HOSTPORT/health"
  # Kind maps Traefik's plain-HTTP entrypoint to this port; the Ingress uses only websecure.
  HTTP_ENTRY="${HTTP_ENTRY:-http://localhost:8080}"
  check "plain HTTP entrypoint does not route to the service (no 200)" no \
    status_is 200 -H "Host: ${HOSTPORT%:*}" "${AUTH_ARGS[@]}" "$HTTP_ENTRY/health"
fi

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
