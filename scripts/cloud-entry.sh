#!/usr/bin/env bash
# EXP-07: run on the k6 VM. Maps the entry ports that the measurement scripts
# use on Kind to the role=api node of a managed cluster, in the kernel (no
# extra process in the path):
#   localhost:8010 -> NODE_IP:30010   (NodePort of fastapi or the gateway)
#   localhost:8080 -> NODE_IP:8000    (Traefik HTTP, used by verify-controls.sh)
#   localhost:8443 -> NODE_IP:443     (Traefik HTTPS)
# URLs, the ingress host and the TLS certificate (both "localhost") therefore
# stay as on Kind, where Docker maps the same ports to the Kind node.
#
# Usage: sudo ./scripts/cloud-entry.sh NODE_IP     set up (re-runnable)
#        sudo ./scripts/cloud-entry.sh --off       remove
set -euo pipefail

ARG="${1:?usage: cloud-entry.sh NODE_IP | --off}"
CHAIN=THESIS_ENTRY

remove() {
  iptables -t nat -D OUTPUT -d 127.0.0.1/32 -p tcp -j "$CHAIN" 2>/dev/null || true
  # The source-NAT rule carries a comment, so exactly this rule is removed.
  { iptables -t nat -S POSTROUTING | grep -- "--comment $CHAIN" || true; } | sed 's/^-A /-D /' \
    | while read -r rule; do eval iptables -t nat "$rule"; done
  # Rule of the first version (source NAT for all traffic from 127.0.0.1).
  iptables -t nat -D POSTROUTING -s 127.0.0.1/32 -j MASQUERADE 2>/dev/null || true
  iptables -t nat -F "$CHAIN" 2>/dev/null || true
  iptables -t nat -X "$CHAIN" 2>/dev/null || true
}

remove
if [ "$ARG" = "--off" ]; then
  sysctl -qw net.ipv4.conf.all.route_localnet=0
  echo "== entry mapping removed"
  exit 0
fi

NODE_IP="$ARG"
# Packets to 127.0.0.1 may only leave the host with route_localnet, and need a
# real source address (MASQUERADE) to get an answer. Only the redirected
# connections to the node get it; other loopback traffic, such as DNS queries
# to the local resolver on 127.0.0.53, must keep 127.0.0.1.
sysctl -qw net.ipv4.conf.all.route_localnet=1
iptables -t nat -N "$CHAIN"
iptables -t nat -A "$CHAIN" -p tcp --dport 8010 -j DNAT --to-destination "$NODE_IP:30010"
iptables -t nat -A "$CHAIN" -p tcp --dport 8080 -j DNAT --to-destination "$NODE_IP:8000"
iptables -t nat -A "$CHAIN" -p tcp --dport 8443 -j DNAT --to-destination "$NODE_IP:443"
iptables -t nat -A OUTPUT -d 127.0.0.1/32 -p tcp -j "$CHAIN"
iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -d "$NODE_IP/32" -m conntrack --ctstate DNAT \
  -m comment --comment "$CHAIN" -j MASQUERADE

echo "== entry mapping to $NODE_IP"
iptables -t nat -S "$CHAIN"
iptables -t nat -S POSTROUTING | grep -- "--comment $CHAIN"
