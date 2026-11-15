#!/usr/bin/env bash
# Install Linkerd (open-source edge channel) with its own certificates.
# Certificates go to certs/linkerd/ (git-ignored) and are only created once.
# Chart versions are pinned (see below). Override: LINKERD_CRDS_CHART_VERSION, LINKERD_CHART_VERSION
set -euo pipefail

cd "$(dirname "$0")/.."

CERT_DIR="certs/linkerd"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/ca.crt" ]; then
  # Trust anchor (root) and issuer certificate, both ECDSA P-256.
  openssl ecparam -name prime256v1 -genkey -noout -out "$CERT_DIR/ca.key"
  openssl req -x509 -new -key "$CERT_DIR/ca.key" -sha256 -days 400 \
    -subj "/CN=root.linkerd.cluster.local" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -out "$CERT_DIR/ca.crt"

  openssl ecparam -name prime256v1 -genkey -noout -out "$CERT_DIR/issuer.key"
  openssl req -new -key "$CERT_DIR/issuer.key" \
    -subj "/CN=identity.linkerd.cluster.local" -out "$CERT_DIR/issuer.csr"
  printf '%s\n' \
    "basicConstraints=critical,CA:TRUE,pathlen:0" \
    "keyUsage=critical,keyCertSign,cRLSign" \
    "subjectKeyIdentifier=hash" \
    "authorityKeyIdentifier=keyid,issuer" > "$CERT_DIR/issuer.ext"
  openssl x509 -req -in "$CERT_DIR/issuer.csr" \
    -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
    -sha256 -days 365 -extfile "$CERT_DIR/issuer.ext" -out "$CERT_DIR/issuer.crt"
  rm -f "$CERT_DIR/issuer.csr" "$CERT_DIR/issuer.ext" "$CERT_DIR"/*.srl
  chmod 600 "$CERT_DIR"/*.key
  echo "created Linkerd certificates in $CERT_DIR"
fi

helm repo add linkerd-edge https://helm.linkerd.io/edge >/dev/null 2>&1 || true
helm repo update >/dev/null

# Pinned to the charts used in the EXP-06 runs (results/exp-06-final/*-environment.txt).
LINKERD_CRDS_CHART_VERSION="${LINKERD_CRDS_CHART_VERSION:-2026.10.1}"
LINKERD_CHART_VERSION="${LINKERD_CHART_VERSION:-2026.10.1}"
# Linkerd needs the Gateway API CRDs; the chart installs them only when asked.
CRDS_ARGS=(--version "$LINKERD_CRDS_CHART_VERSION" --set installGatewayAPI=true)
CP_ARGS=(--version "$LINKERD_CHART_VERSION")

helm upgrade --install linkerd-crds linkerd-edge/linkerd-crds \
  --namespace linkerd --create-namespace "${CRDS_ARGS[@]}"

helm upgrade --install linkerd-control-plane linkerd-edge/linkerd-control-plane \
  --namespace linkerd \
  --set-file identityTrustAnchorsPEM="$CERT_DIR/ca.crt" \
  --set-file identity.issuer.tls.crtPEM="$CERT_DIR/issuer.crt" \
  --set-file identity.issuer.tls.keyPEM="$CERT_DIR/issuer.key" \
  "${CP_ARGS[@]}"

for d in $(kubectl -n linkerd get deploy -o name); do
  kubectl -n linkerd rollout status "$d" --timeout=300s
done

echo "== versions in use =="
helm list -n linkerd
kubectl -n linkerd get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.template.spec.containers[0].image}{"\n"}{end}'
kubectl -n linkerd get pods -o wide
