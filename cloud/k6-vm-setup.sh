#!/usr/bin/env bash
# EXP-07: prepare the k6 VM (Ubuntu 24.04). Installs the tools in the versions
# used on Kind, clones the repository, connects kubectl to the cluster and maps
# the entry ports (scripts/cloud-entry.sh). Re-runnable.
#
# Usage on the VM: API_IP=10.x.y.z CLUSTER=thesis-eks REGION=eu-north-1 bash k6-vm-setup.sh
set -euo pipefail

API_IP="${API_IP:?private IP of the role=api node}"
CLUSTER="${CLUSTER:-thesis-eks}"
REGION="${REGION:-eu-north-1}"
K6_VERSION=v2.0.0              # as on Kind (results/*/*-environment.txt)
HELM_VERSION=v3.21.3
KUBECTL_VERSION=v1.36.4        # matches the cluster minor version
LINKERD_VERSION=edge-26.7.2    # CLI used on Kind
REPO=https://github.com/farrukhshafique87/secure-llm-serving-kubernetes.git

sudo apt-get update -qq
sudo apt-get install -y -qq git curl unzip jq make python3-venv util-linux iptables >/dev/null

if ! k6 version 2>/dev/null | grep -q "$K6_VERSION"; then
  curl -sSL "https://github.com/grafana/k6/releases/download/$K6_VERSION/k6-$K6_VERSION-linux-amd64.tar.gz" \
    | tar xz -C /tmp
  sudo install "/tmp/k6-$K6_VERSION-linux-amd64/k6" /usr/local/bin/k6
fi
if ! kubectl version --client 2>/dev/null | grep -q "$KUBECTL_VERSION"; then
  curl -sSLo /tmp/kubectl "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
  sudo install /tmp/kubectl /usr/local/bin/kubectl
fi
if ! helm version --short 2>/dev/null | grep -q "$HELM_VERSION"; then
  curl -sSL "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" | tar xz -C /tmp
  sudo install /tmp/linux-amd64/helm /usr/local/bin/helm
fi
if ! command -v aws >/dev/null; then
  curl -sSLo /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
  unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install --update >/dev/null
fi
if ! "$HOME/.linkerd2/bin/linkerd" version --client 2>/dev/null | grep -q "$LINKERD_VERSION"; then
  curl -sSL https://run.linkerd.io/install-edge | LINKERD2_VERSION="$LINKERD_VERSION" sh >/dev/null
fi
grep -q linkerd2 "$HOME/.bashrc" || echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> "$HOME/.bashrc"

[ -d "$HOME/thesis-llm-kubernetes" ] || git clone -q "$REPO" "$HOME/thesis-llm-kubernetes"
grep -q "PLATFORM=cloud" "$HOME/.bashrc" || echo 'export PLATFORM=cloud' >> "$HOME/.bashrc"

aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION" --alias "$CLUSTER" >/dev/null
kubectl get nodes -L role
sudo "$HOME/thesis-llm-kubernetes/scripts/cloud-entry.sh" "$API_IP"

echo "== versions"
k6 version; kubectl version --client | head -1; helm version --short
"$HOME/.linkerd2/bin/linkerd" version --client
