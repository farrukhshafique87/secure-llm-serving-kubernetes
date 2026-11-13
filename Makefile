.PHONY: help format lint validate validate-kube validate-yaml test clean \
        kind-up kind-down metrics-server monitoring \
        build load build-gateway load-gateway secrets ingress linkerd \
        deploy pull-model pause resume verify measure measure-load

SHELL := /bin/bash

IMAGE ?= llm-api:1.0.0
GATEWAY_IMAGE ?= llm-gateway:1.0.0
CLUSTER ?= thesis-cluster
# Configuration name as in scripts/lib/configs.sh (c0-baseline ... c6-all).
CONFIG ?= c0-baseline
# Sets OVERLAY and NS for $(CONFIG).
CFG = . scripts/lib/configs.sh && config_vars $(CONFIG)

help:
	@echo "Code quality:  format lint test validate"
	@echo "Cluster:       kind-up kind-down metrics-server monitoring"
	@echo "Images:        build load build-gateway load-gateway"
	@echo "Secure setup:  secrets ingress linkerd (once)"
	@echo "Environment:   deploy pull-model pause resume verify  [CONFIG=c0-baseline]"
	@echo "Measurement:   measure measure-load  CONFIG=<config> REP=<n>"
	@echo "Configs: c0-baseline c1-rbac c2-netpol c3-mtls c4-tls c5-gateway c6-all"
	@echo "Only one environment may run at a time: make pause CONFIG=<other> first."

format:
	ruff format .
	ruff check --fix .

lint:
	ruff check .

validate-yaml:
	yamllint .

validate-kube:
	for overlay in kubernetes/overlays/*/; do \
	  echo "== $$overlay"; \
	  kubectl kustomize "$$overlay" | kubeconform -strict -summary || exit 1; \
	done

validate: lint validate-yaml validate-kube

test:
	cd apps/llm-api && pytest
	cd apps/llm-gateway && pytest

kind-up:
	./scripts/kind-up.sh

kind-down:
	kind delete cluster --name $(CLUSTER)

metrics-server:
	./scripts/install-metrics-server.sh

monitoring:
	./scripts/install-monitoring.sh

build:
	docker build -t $(IMAGE) apps/llm-api

load:
	kind load docker-image $(IMAGE) --name $(CLUSTER)

build-gateway:
	docker build -t $(GATEWAY_IMAGE) apps/llm-gateway

load-gateway:
	kind load docker-image $(GATEWAY_IMAGE) --name $(CLUSTER)

secrets:
	./scripts/gen-secrets.sh

ingress:
	./scripts/install-ingress.sh

linkerd:
	./scripts/install-linkerd.sh

deploy:
	$(CFG) && kubectl apply -k "kubernetes/overlays/$$OVERLAY"

pull-model:
	$(CFG) && ./scripts/pull-model.sh "$$NS" "kubernetes/overlays/$$OVERLAY"

pause:
	$(CFG) && ./scripts/pause-env.sh "$$NS"

resume:
	$(CFG) && ./scripts/resume-env.sh "kubernetes/overlays/$$OVERLAY" "$$NS"

verify:
	$(CFG) && ./scripts/verify-controls.sh "$$NS" "$$URL"

# make measure CONFIG=c1-rbac REP=1
measure:
	./scripts/measure-config.sh $(CONFIG) $(REP)

# make measure-load CONFIG=c6-all REP=1 [PATHS=health]
measure-load:
	./scripts/measure-load.sh $(CONFIG) $(REP)

clean:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
