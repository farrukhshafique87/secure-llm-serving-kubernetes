# Research Traceability Matrix

## 1. Purpose

This document connects the research questions of the thesis with the implementation work, experimental activities, measurable variables, and evidence produced by the project.

The matrix is intended to maintain research traceability throughout the project. It will be updated as implementation and experiments progress.

The thesis focuses on the secure distributed deployment and performance evaluation of Large Language Models (LLMs) on Kubernetes clusters. The evaluation considers performance, scalability, resource utilization, reliability, and the effects of security controls.

---

## 2. Research Questions

### RQ1 — Total Security Overhead

**What total performance overhead (latency, throughput, resource consumption) is introduced when standard cloud-native security controls are layered onto a distributed LLM serving stack on Kubernetes?**

The unsecured baseline is compared with the fully secured configuration (RBAC, NetworkPolicies, mTLS, Secrets Management, a TLS ingress controller and an authenticated API gateway) under identical workloads.

### RQ2 — Effect of the Deployment Environment

**Does the measured security overhead differ between a local cluster (Kind) and a managed cloud Kubernetes cluster (AKS, EKS or GKE)?**

The baseline-versus-secure comparison of RQ1 is repeated in each environment. Results are reported per environment, because Kind results do not automatically represent managed cloud behaviour.

### RQ3 — Overhead per Security Control

**Which individual security control introduces the most overhead?**

Each control is enabled on its own against the baseline so that the total overhead of RQ1 can be attributed to individual controls. NetworkPolicy overhead is reported as enforced by the chosen CNI (Calico).

### Supporting experiments (not research questions)

Workload intensity (EXP-02), replica count (EXP-03) and resource limits (EXP-04) characterise the baseline and test whether the security overhead is sensitive to them. They support RQ1 but do not form separate research questions.

---

## 3. Research Traceability Matrix

### 3.0 Experiment roles

| Role            | Meaning                                 |
| --------------- | --------------------------------------- |
| Primary         | Directly answers the RQ                 |
| Reference       | Baseline others are compared with       |
| Operating point | Fixes the load level used later         |
| Sensitivity     | Tests if overhead depends on a variable |
| Verification    | Proves controls work before measuring   |
| Prerequisite    | Platform must work first                |

### 3.1 Metric codes

| Code | Metric                            |
| ---- | --------------------------------- |
| L    | Latency P50 / P95 / P99           |
| T    | Throughput (requests/s)           |
| E    | Error rate                        |
| C    | CPU utilisation                   |
| M    | Memory utilisation                |
| S    | Generation speed (tokens/s)       |
| A    | Availability (readiness, success) |
| B    | Allowed / blocked traffic check   |

### 3.2 RQ to experiment map

| RQ  | Exp    | Role            | Variable              | Metrics     | Status    |
| --- | ------ | --------------- | --------------------- | ----------- | --------- |
| RQ1 | EXP-00 | Prerequisite    | Deployment health     | A           | Completed |
| RQ1 | EXP-01 | Reference       | 1 VU, unsecured       | L T E C M S | Completed |
| RQ1 | EXP-02 | Operating point | VUs / request rate    | L T E C M   | Completed |
| RQ1 | EXP-03 | Sensitivity     | Replica count         | L T E C M   | Kind done |
| RQ1 | EXP-04 | Sensitivity     | CPU / memory limits   | L T E C M   | Completed |
| RQ1 | EXP-05 | Verification    | Controls work         | A B         | Completed |
| RQ1 | EXP-06 | Primary         | Baseline vs secure    | L T E C M S | Kind done |
| RQ2 | EXP-07 | Primary         | Kind vs managed cloud | L T E C M S | Planned   |
| RQ3 | EXP-05 | Verification    | Per-control checks    | A B         | Completed |
| RQ3 | EXP-06 | Primary         | One control at a time | L T E C M S | Kind done |

CPU, CPU throttling and memory per container are collected through cAdvisor in Prometheus (`docs/notes/monitoring.md`).

### 3.3 Evidence per experiment

| Exp    | Evidence                                     |
| ------ | -------------------------------------------- |
| EXP-00 | kubectl, probes, logs, Prometheus            |
| EXP-01 | k6 summary JSON, Prometheus, env record      |
| EXP-02 | k6 summary JSON, Prometheus, env record      |
| EXP-03 | k6 summary JSON, Prometheus, replica config  |
| EXP-04 | k6 summary JSON, Prometheus, resource config |
| EXP-05 | Security manifests, allow/deny test logs     |
| EXP-06 | k6 summary JSON, Prometheus, overlay configs |
| EXP-07 | Same as EXP-06, per environment              |

---

## 4. Experiment Traceability

### EXP-00 — Deployment and Monitoring Verification

**Purpose:**
Verify that the Kubernetes-based LLM serving environment is operational before performance experiments begin.

**Main components:**

* Kubernetes cluster
* FastAPI service
* Ollama inference service
* Kubernetes Services
* Health and readiness probes
* Prometheus
* Grafana
* Metrics Server

**Verification areas:**

* Kubernetes workloads start successfully.
* FastAPI becomes ready only when its required dependency is available.
* Ollama is reachable by the application.
* Kubernetes Services provide the expected communication paths.
* Prometheus receives application metrics.
* Grafana can visualize collected metrics.
* The `/chat` endpoint can successfully invoke the LLM.

This experiment establishes the technical baseline for later controlled experiments.

---

### EXP-01 — Baseline Load

**Purpose:**
Measure the performance of the initial LLM deployment under a controlled low-load workload.

**Primary independent variable:**

* Workload intensity.

**Example configuration:**

* Virtual users: 1
* Duration: 5 minutes
* Fixed prompt
* HTTP request to `/chat`

**Primary measurements:**

* P50 latency
* P95 latency
* P99 latency
* Throughput
* Error rate
* CPU utilization
* Memory utilization

**Tools:**

* k6
* Prometheus
* Grafana
* Kubernetes metrics

The baseline experiment provides a reference point for subsequent load, scaling, resource, and security experiments.

---

### EXP-02 — Load and Stress Evaluation

**Purpose:**
Determine how increasing workload affects the LLM serving system.

**Independent variable:**

* Number of virtual users and/or request rate.

**Measurements:**

* P50 latency
* P95 latency
* P99 latency
* Throughput
* Error rate
* CPU utilization
* Memory utilization

**Purpose of comparison:**

The results will show whether increased workload primarily affects latency, throughput, resource utilization, or reliability.

---

### EXP-03 — Horizontal Scaling

**Purpose:**
Evaluate the effect of increasing the number of Kubernetes replicas on LLM serving performance.

**Independent variable:**

* Number of serving replicas.

**Potential configurations:**

* 1 replica
* 2 replicas
* Additional replicas where supported by the experimental environment

**Measurements:**

* P50 latency
* P95 latency
* P99 latency
* Throughput
* Error rate
* CPU utilization
* Memory utilization
* Resource consumption per replica

**Research relevance:**

The experiment is a sensitivity analysis supporting RQ1: it shows how baseline performance scales with replicas and whether the security overhead changes with replica count.

---

### EXP-04 — Resource Allocation

**Purpose:**
Investigate the relationship between Kubernetes resource allocation and LLM inference performance.

**Independent variables:**

* CPU requests/limits
* Memory requests/limits

**Measurements:**

* P50 latency
* P95 latency
* P99 latency
* Throughput
* Error rate
* CPU utilization
* Memory utilization

**Research relevance:**

The experiment is a sensitivity analysis supporting RQ1 and RQ3: it shows how resource allocation influences performance and whether controls that add CPU or memory demand (for example the mTLS proxy) are limited by the allocation.

---

### EXP-05 — Security Configuration Verification

**Purpose:**
Implement and verify Kubernetes security controls before measuring their performance impact.

**Security mechanisms within the planned scope:**

* RBAC
* Network Policies
* Secrets
* TLS and/or mTLS where applicable

**Verification areas:**

* Unauthorized access is rejected.
* Required service communication remains functional.
* Network restrictions behave as intended.
* Sensitive configuration is not unnecessarily exposed.
* Secure communication operates correctly where implemented.

**Important distinction:**

EXP-05 primarily verifies **security functionality**. Performance overhead should be evaluated separately through EXP-06.

---

### EXP-06 — Secure Deployment Performance

**Purpose:**
Measure the performance impact of security controls applied to the Kubernetes-based LLM deployment.

**Comparison:**

```text
Baseline configuration
        ↓
Security controls applied
        ↓
Same workload
        ↓
Comparable measurements
        ↓
Performance difference
```

**Independent variable:**

* Security configuration.

**Dependent variables:**

* P50 latency
* P95 latency
* P99 latency
* Throughput
* Error rate
* CPU utilization
* Memory utilization

**Primary analysis:**

The experiment will determine whether security mechanisms introduce measurable overhead and whether that overhead is significant relative to the baseline.

**RQ3 extension (overhead per control):**

The same workload is run for each configuration, one control at a time, against the baseline:

| Configuration | Controls enabled                      |
| ------------- | ------------------------------------- |
| C0            | None (baseline)                       |
| C1            | RBAC                                  |
| C2            | NetworkPolicies (Calico)              |
| C3            | mTLS (Linkerd, edge channel)          |
| C4            | TLS ingress (Traefik)                 |
| C5            | Authentication gateway (API key)      |
| C6            | All controls (total overhead for RQ1) |

Secrets Management stores the TLS private key (C4) and the gateway API key (C5). It is expected to add no per-request cost, so it is verified functionally in EXP-05 and is not ranked as a separate configuration in RQ3.

The upstream NGINX Ingress controller was retired in March 2026 (no further fixes, including security fixes), so Traefik is used as the maintained ingress controller.

Each configuration is measured on two paths: the full `/chat` inference path and a lightweight `/health` path. Inference takes seconds, so small per-request overhead can disappear in the inference variance; the `/health` path exposes it.

---

### EXP-07 — Local versus Managed Cloud

**Purpose:**
Repeat EXP-06 unchanged on a managed cloud Kubernetes cluster and compare the security overhead with the local Kind result (RQ2).

**Independent variable:**

* Environment (Kind; one managed cloud: AKS, EKS or GKE).

**Controlled variables:**

* Same images, model, prompts, load profile, resource requests/limits and security configuration.

**Primary analysis:**

The comparison is of *relative overhead* (secured versus baseline) within each environment. Absolute latency and throughput differ with hardware and are reported per environment, not compared directly.

---

## 5. Measurement Categories

| Category            | Metrics                     | Purpose                        |
| ------------------- | --------------------------- | ------------------------------ |
| Latency             | P50/P95/P99                 | Response-time distribution     |
| Throughput          | Requests/sec                | Serving capacity               |
| Generation speed    | Tokens/sec                  | LLM-specific serving speed     |
| Reliability         | Failed requests/error rate  | Service stability              |
| CPU                 | CPU usage                   | Compute consumption            |
| Memory              | Memory usage                | Memory consumption             |
| Scaling             | Performance vs. replicas    | Scaling behavior               |
| Resource efficiency | Performance vs. resources   | Resource-performance trade-off |
| Security overhead   | Baseline vs. secure         | Security-performance impact    |
| Availability        | Readiness/liveness, success | Operational reliability        |

---

## 6. Evidence Sources

The research will use multiple forms of evidence rather than relying on a single measurement source.

| Evidence Source    | Evidence Provided                                                     |
| ------------------ | --------------------------------------------------------------------- |
| Kubernetes         | Pod status, replica count, resource configuration, deployment state   |
| `kubectl`          | Operational verification and configuration inspection                 |
| FastAPI            | Application behavior, health/readiness endpoints and request handling |
| Ollama             | LLM serving availability and inference behavior                       |
| k6                 | Workload generation, latency, throughput and error measurements       |
| Prometheus         | Time-series performance and resource metrics                          |
| Grafana            | Visualization and monitoring dashboards                               |
| Kubernetes logs    | Operational and application-level troubleshooting evidence            |
| Security manifests | RBAC, NetworkPolicy, Secrets and TLS/mTLS configuration evidence      |
| Experiment records | Reproducibility information and experiment configuration              |

---

## 7. Baseline and Comparison Principle

The experiments should use a controlled comparison approach.

The baseline configuration represents the reference deployment before the security-related changes being evaluated.

For security experiments:

```text
Baseline
   │
   ├── Same application
   ├── Same LLM model
   ├── Same workload
   ├── Same resource configuration
   └── Same measurement process
          │
          ▼
Secured configuration
   │
   ├── Same application
   ├── Same LLM model
   ├── Same workload
   ├── Comparable resource configuration
   └── Same measurement process
          │
          ▼
Performance difference
```

The purpose is to isolate the effect of the security configuration as far as practical.

Changes to hardware, model version, workload, resource allocation, or deployment architecture must be recorded because they can affect comparability.

---

## 8. Experiment Status

| Experiment                     | Status               | Next Requirement              |
| ------------------------------ | -------------------- | ----------------------------- |
| EXP-00 Deployment & Monitoring | Completed / baseline | Final verification            |
| EXP-01 Baseline Load           | Completed            | Re-run on v1.36.4, methodology §13 |
| EXP-02 Load & Stress           | Completed (Kind)     | Results in methodology §9.6   |
| EXP-03 Horizontal Scaling      | Completed (Kind)     | Results in methodology §12.4, §12.8 |
| EXP-04 Resource Allocation     | Completed (Kind)     | Results in methodology §10.4  |
| EXP-05 Security Verification   | Completed            | -                             |
| EXP-06 Secure Performance      | Kind done            | Repeat on cloud (EXP-07)      |
| EXP-07 Local vs Cloud          | Planned              | Needs managed cloud access    |

---

## 9. Research-to-Thesis Traceability

| Thesis Area                      | RQ         | Supporting Evidence                         |
| -------------------------------- | ---------- | ------------------------------------------- |
| K8s deployment architecture      | Foundation | Manifests, overlays, Services               |
| LLM serving                      | Foundation | Ollama, FastAPI, inference tests            |
| Monitoring & observability       | RQ1–RQ3    | Prometheus, Grafana, K8s metrics            |
| Baseline characterisation        | RQ1        | EXP-01, EXP-02                              |
| Sensitivity (scaling, resources) | RQ1, RQ3   | EXP-03, EXP-04                              |
| Security implementation          | RQ1, RQ3   | RBAC, NetworkPolicy, Secrets, mTLS, gateway |
| Security functionality check     | RQ1, RQ3   | EXP-05 allow/deny tests                     |
| Total security overhead          | RQ1        | EXP-06 baseline vs all controls             |
| Local vs cloud comparison        | RQ2        | EXP-07 per-environment results              |
| Overhead per control             | RQ3        | EXP-06 one-control-at-a-time                |

---

## 10. Research Integrity Rules

The following rules apply when this matrix is updated:

1. **No measured result is entered before the corresponding experiment has actually been executed.**
2. Planned experiments must remain marked as planned until they are implemented and executed.
3. Experimental measurements must be traceable to a documented experiment configuration.
4. Baseline and secured configurations must be comparable before drawing performance conclusions.
5. Configuration changes that can influence performance must be recorded.
6. Results must be distinguished from assumptions, hypotheses, expectations, and acceptance thresholds.
7. A k6 threshold is not itself an experimental result.
8. Monitoring data must be preserved or exported when it is used as thesis evidence.
9. Security functionality and security-performance overhead are treated as separate evaluation activities.
10. The final thesis conclusions must be based on measured experimental evidence rather than expected behavior.

---

## 11. Planned Result Structure

Experimental results should eventually be stored separately from experiment definitions.

```text
tests/
└── k6/
    ├── baseline.js
    ├── load.js
    ├── stress.js
    ├── scaling.js
    ├── resources.js
    ├── health-path.js
    └── security.js

results/
├── exp-01-baseline/
├── exp-02-load-stress/
├── exp-03-horizontal-scaling/
├── exp-04-resource-allocation/
├── exp-05-security-verification/
├── exp-06-security-performance/
└── exp-07-environment-comparison/
```

The exact result structure may be refined when the experiments are implemented.

---

## 12. Current Scope Boundary

The traceability matrix represents the current research direction and implementation plan. It does not claim that all listed experiments or security mechanisms have already been implemented or evaluated.

At the current project stage, the Kubernetes deployment, application health/readiness behavior, monitoring foundation, and initial k6 baseline workload form the existing experimental foundation. Security evaluation, systematic performance experiments, scaling evaluation, resource experiments, and cloud-based evaluation remain subsequent project activities.
