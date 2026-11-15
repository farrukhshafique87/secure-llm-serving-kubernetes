# Experiment Methodology

Status: draft.
This document defines how each experiment is run. Results are stored in `results/`.

## 1. Fixed decisions

| Topic            | Decision                                                           |
| ---------------- | ------------------------------------------------------------------ |
| Research Qs      | RQ1 total overhead, RQ2 local vs cloud, RQ3 per-control            |
| Deadline         | December 2026                                                      |
| Model            | Qwen2.5 0.5b via Ollama                                            |
| Inference params | temperature 0.0, seed 42, 64 output tokens, model kept loaded      |
| Configuration    | Kustomize: one base, overlays per environment and security level   |
| Baseline         | `kind-baseline` overlay: no security controls                      |
| Secure           | `kind-secure` overlay: controls added as Kustomize components      |
| Ingress          | Traefik                                                            |
| Gateway          | Own FastAPI gateway pod: API key from a Secret, route allowlist    |
| TLS              | Self-signed EC P-256 certificate, terminated at the ingress        |
| mTLS             | Linkerd edge channel                                               |
| Secure entry     | https://localhost:8443 (k6: K6_INSECURE_SKIP_TLS_VERIFY=true)      |
| Run rule         | Only ONE environment (baseline or secure) runs at a time           |
| CNI              | Calico in all runs (baseline and secure)                           |

## 2. What "baseline" contains

The baseline has no RBAC restrictions beyond defaults, no NetworkPolicies, no
mTLS, no application Secrets and no ingress/authentication gateway. Container
hardening already in the base manifests (non-root user, dropped capabilities)
is part of **every** configuration and is therefore not counted as overhead.

## 3. Controlled variables

Same container images, model and model version, prompt, inference parameters,
Ollama settings (keep-alive, parallelism), resource requests/limits, Kubernetes
and Calico versions, load profile and tool versions. Any change is recorded in
the environment record (`scripts/record-environment.sh`).

## 4. Run protocol

1. Pause the other environments (`make pause CONFIG=<config>`; the measurement
   scripts do this themselves).
2. Run `scripts/record-environment.sh results/<exp>/ <namespace>`.
3. Run `tests/k6/smoke.js`. Abort if it fails.
4. Warm-up: 1 minute of the same load, discarded.
5. Measured run: 5 minutes, `--summary-export` to `results/<exp>/`.
6. Cool-down 2 minutes. Repeat for at least 3 repetitions (5 if time allows).
7. Interleave configurations (C0, C1, … C0, C1, …) instead of running all
   repetitions of one configuration first, to spread out time-dependent noise.
8. Close other heavy applications on the host during runs.

## 5. Two measurement paths

| Path        | Endpoint  | Why                                                        |
| ----------- | --------- | ---------------------------------------------------------- |
| Full        | `/chat`   | Realistic end-to-end cost including inference              |
| Lightweight | `/health` | No inference: exposes the per-request cost of the controls |

## 6. Analysis

Per configuration: mean of the per-run averages, with the min–max spread over the
repetitions (computed by `scripts/overhead_table.py`). Overhead =
(secured − baseline) / baseline for average latency, P95, P99, CPU and memory.
The spread is reported so that differences inside the noise are not claimed as
overhead. Kind and cloud results are reported separately (RQ2).

## 7. Threats to validity

* Kind nodes are containers on one machine: no real network between nodes, and
  the load generator shares the host CPU.
* CPU-only inference; results do not transfer to GPU serving.
* Overhead of NetworkPolicies is specific to the CNI (Calico).
* Single model, single prompt, small repetition count.
* Cloud node types differ from the laptop, so only the relative overhead will be compared.
* k6 reuses connections, so the TLS handshake cost is spread over many requests;
  handshake cost alone is not measured.
* The lab certificate is self-signed and k6 skips certificate verification, so
  certificate validation cost is not included.
* TLS ends at the ingress; hops behind it are plain HTTP until mTLS (C3) is on.
* The gateway is a Python (FastAPI/httpx) proxy; its overhead reflects this
  implementation, not API gateways in general.
* Linkerd's open-source project publishes edge releases only; the chart and
  proxy versions are recorded in the environment record of each run.

## 8. Configurations and entry points

| Config      | Overlay         | Namespace      | Entry                  | Key |
| ----------- | --------------- | -------------- | ---------------------- | --- |
| c0-baseline | kind-baseline   | llm-baseline   | http://localhost:8010  | no  |
| c1-rbac     | kind-c1-rbac    | llm-c1-rbac    | http://localhost:8010  | no  |
| c2-netpol   | kind-c2-netpol  | llm-c2-netpol  | http://localhost:8010  | no  |
| c3-mtls     | kind-c3-mtls    | llm-c3-mtls    | http://localhost:8010  | no  |
| c4-tls      | kind-c4-tls     | llm-c4-tls     | https://localhost:8443 | no  |
| c5-gateway  | kind-c5-gateway | llm-c5-gateway | http://localhost:8010  | yes |
| c6-all      | kind-secure     | llm-secure     | https://localhost:8443 | yes |
| c5-gateway-cpu1000 | kind-c5-gateway-cpu1000 | llm-c5-gateway | http://localhost:8010 | yes |

c5-gateway-cpu1000 exists only for EXP-04 (§10): it is c5-gateway with the gateway
CPU limit at 1000 m instead of 500 m and shares its namespace.

C3 uses Linkerd. Only hops between meshed workloads use mTLS; Traefik is not
meshed, so the hop from the ingress to the gateway is plain HTTP.

Configurations without an
ingress are reached through a NodePort on the Kind control-plane node;
configurations with TLS go through Traefik. The entry path is therefore part of
what each configuration changes.

Each configuration runs in its own namespace with its own model volume. Only one
namespace is active at a time; `scripts/measure-config.sh` pauses the others,
starts the requested one, and runs the `/chat` and `/health` tests. Repetitions
are interleaved by looping over the configurations for each repetition.

## 9. EXP-02 load sweep

EXP-06 measured every configuration at one load level (`/chat` with 1 VU,
`/health` at 50 req/s). EXP-02 tests whether the overhead stays the same when
the load rises, and fixes the operating point used for EXP-03, EXP-04 and EXP-07.

### 9.1 Design

| Item          | `/health` sweep                         | `/chat` sweep                    |
| ------------- | --------------------------------------- | -------------------------------- |
| Configs       | c0-baseline, c5-gateway, c6-all         | c0-baseline, c6-all              |
| Levels        | 50, 60, 70, 80, 90, 100 req/s (c0 also 150, 200) | 1, 2, 4 VUs (think time 1 s) |
| Executor      | constant arrival rate                   | constant VUs                     |
| Measured run  | 2 min                                   | 3 min                            |
| Warm-up       | 30 s, discarded                         | 1 min, discarded                 |
| Cool-down     | 60 s                                    | 120 s                            |
| Repetitions   | 3, interleaved over configurations      | 3, interleaved over configurations |
| Monitoring    | `MONITOR=1` for every run               | `MONITOR=1` for every run        |

C5 is included because the gateway added the largest share of the `/health`
overhead in EXP-06. The `/health` levels were chosen from the pilot (§9.5): they
cover the range in which the gateway configurations stop keeping up; c0 also runs
at 150 and 200 req/s to show its own headroom. Within one configuration the levels run from lowest to
highest; the cool-down after each level separates them.

Script: `scripts/measure-load.sh`; tables: `scripts/load_table.py`.
Results: `results/exp-02-load/`.

### 9.2 Hypotheses (stated before the runs)

* **H2.1 (`/chat`).** Ollama serves one request at a time (`OLLAMA_NUM_PARALLEL=1`).
  Throughput is therefore capped near 1 / inference time, and above 1 VU the
  extra requests wait in a queue, so latency grows with the number of VUs. The
  difference between c0 and c6 stays inside the run-to-run spread at every level.
* **H2.2 (`/health`).** At low rates the c6 − c0 difference stays close to the
  EXP-06 value (about 5 ms). It grows once a container on the path nears its CPU
  limit. In EXP-06 the gateway used about 140 m at 50 req/s against a 500 m limit,
  so the gateway is expected to saturate first, somewhere between 150 and 200 req/s,
  while the baseline is expected to keep up at all tested rates.

### 9.3 Saturation rule

A `/health` level counts as saturated when the achieved rate is below 95 % of
the target, k6 reports dropped iterations, or more than 1 % of requests fail.
Latency of a saturated level is reported but not used as overhead, because it
measures queueing rather than the cost of a control.

### 9.4 Limits of this experiment

* k6 runs on the same host as the Kind nodes. At high rates it competes with the
  cluster for CPU; this affects all configurations, but not necessarily equally.
* `kubectl top` reports CPU per pod. In c6 the gateway pod also contains the
  Linkerd proxy, while the 500 m limit applies to the gateway container only.
  The CPU throttling of each container is therefore taken from the cAdvisor
  counters in Prometheus (`docs/notes/monitoring.md`), not from `kubectl top`.
* The saturation point depends on the CPU limits chosen in the manifests. EXP-04
  can test this directly by raising the gateway limit.
* The host was not equally fast in all repetitions. Repetition 1 was slower for
  every configuration (c0 median at 50 to 100 req/s: 2.07 to 2.25 ms against
  1.88 to 1.93 ms in repetition 3), and four of the five collapsed runs fall into repetition 1.
  Rotating the configuration order spreads this effect over the configurations
  but does not remove it.
* Short stalls of the host (about 1 to 4 s without responses) appear in single
  runs of every configuration, including the baseline. With 3 runs per level,
  the share of collapsed runs is an indication, not a probability estimate.

### 9.5 Pilot (17 Oct 2026, not used for conclusions)

One run per level on `/health`, without live monitoring, to choose the levels of
the full sweep. Data: `results/exp-02-pilot/`.

| Config      | 50 req/s       | 100 req/s                  | 150 req/s                  | 200 req/s                  |
| ----------- | -------------- | -------------------------- | -------------------------- | -------------------------- |
| c0-baseline | ok, 2.58 ms    | ok, 3.04 ms                | ok, 3.02 ms                | ok, 3.98 ms                |
| c5-gateway  | -              | saturated, 69.5 req/s      | saturated, 35.5 req/s      | -                          |
| c6-all      | ok, 9.29 ms    | saturated, 77.6 req/s      | saturated, 32.6 req/s      | saturated, 32.0 req/s      |

Values are the average latency, or the achieved rate for saturated levels.

* Both gateway configurations saturate between 50 and 100 req/s, earlier than
  H2.2 predicted (150 to 200 req/s). H2.2 stays as stated in §9.2 and is tested
  by the full sweep.
* Above saturation the achieved rate falls further instead of staying at a
  maximum, which points to queueing collapse rather than a fixed capacity limit.
* A separate check with live monitoring (c5-gateway, 100 req/s) measured the
  gateway container as CPU-throttled in 99.7 % of scheduler periods (maximum of
  1-minute windows).

### 9.6 Results (17 Oct 2026, 3 repetitions, `MONITOR=1`)

78 runs, all valid (no pod restarts). Data: `results/exp-02-load/`; full tables:
`results/exp-02-load/load-summary.md` (`scripts/load_table.py`); figures:
`fig-overhead-median.png` and `fig-collapsed-runs.png` (`scripts/plot_load.py`).

**`/chat` (H2.1).** Throughput levels off from 2 VUs at 0.42 to 0.43 (c0) and 0.45 to
0.46 (c6) req/s; above that, latency grows with the queue (about 8 s at 4 VUs). c0 and c6
overlap at every level (1 VU: 2.60 s, runs 2.00 to 3.67 s, against 2.35 s, runs
2.13 to 2.71 s). The Ollama container reached 100 % CPU throttling at its 2-CPU
limit in both configurations, so the throughput limit comes from the CPU limit
of Ollama as well as from serving one request at a time. H2.1 is supported, with
this addition to its explanation.

**`/health`, rule of §9.3 (primary, stated before the runs).** c0 counts as
saturated only at 150 req/s, c5 at 50, 70 and 100 req/s, c6 at every level from
60 req/s. Most of these levels are marked because of a few dropped requests in
one run (see below).

**`/health`, per run (post-hoc).** Added after the runs because single host
stalls made the §9.3 rule mark whole levels. Each run is classified as
*collapse* (achieved rate below 95 % of the target, more than 1 % failed, or at
least 1 % of requests dropped), *transient* (some, but under 1 %, dropped) or
*stable* (nothing dropped). The overhead is also given from the median latency
of the runs without collapse.

| Config      | Collapsed runs (of 3) per level                 | Transient runs |
| ----------- | ----------------------------------------------- | -------------- |
| c0-baseline | none at 50 to 200 req/s                         | 1 (150 req/s)  |
| c5-gateway  | 70: 1, 100: 1                                   | 2              |
| c6-all      | 90: 1, 100: 2                                   | 4              |

| Rate req/s | c0 median ms | Δ c5-gateway ms | Δ c6-all ms          |
| ---------- | ------------ | --------------- | -------------------- |
| 50         | 1.98         | +3.38           | +5.62                |
| 60         | 2.08         | +2.81           | +5.45                |
| 70         | 1.99         | +2.66 (2 runs)  | +6.92                |
| 80         | 2.01         | +3.27           | +5.87                |
| 90         | 2.02         | +3.05           | +5.33 (2 runs)       |
| 100        | 1.96         | +3.00 (2 runs)  | n/a (2 of 3 collapsed) |

**H2.2.** The first part is supported: the median overhead stays at about +3 ms
(gateway) and +5.5 ms (all controls) from 50 to 90 req/s. The predicted
saturation point is not: the gateway configurations collapse in single runs from
70 req/s, not from 150 to 200 req/s, while the baseline completes every run up
to 200 req/s. During the sweep the `gateway` container reached 100 % CPU
throttling (maximum of 1-minute windows) in c5 and c6; `fastapi` stayed below
2 % and `linkerd-proxy` below 18 %.

**Interpretation (to be tested).** The gateway runs close to its 500 m CPU limit
at 70 to 100 req/s (c5: 272 to 384 m on average). A short host stall that the
baseline absorbs then builds a queue that the throttled gateway cannot drain, so
the cost of the security path shows as a higher chance of collapse rather than
as a fixed capacity limit. EXP-04 tests this by raising only the gateway CPU
limit; if the interpretation holds, the collapses at 70 to 100 req/s disappear.

**Throttling per run (added 20 Oct 2026).** `scripts/throttle_table.py` reads
the throttling of each container back from Prometheus for the measured window of
each run (`results/exp-02-load/throttling.csv`). All 5 collapsed runs are runs in
which the `gateway` container was throttled heavily: maximum of the 1-minute
windows 61 to 100 %, mean over the run 35 to 100 %. In the 31 runs without
collapse the maximum was at most 34 % and the mean at most 28 %. Within the
measured windows `fastapi` stayed at or below 0.6 % and `linkerd-proxy` at or
below 0.1 %; the 18 % for `linkerd-proxy` given above was read from the
dashboard over the whole sweep, including warm-up and cool-down. The data show
that collapse and gateway throttling occur in the same runs; they cannot show
which of the two comes first (see §10.4).

## 10. EXP-04 gateway CPU limit

EXP-02 left one explanation open (§9.6): the gateway configurations collapse in
single runs from 70 req/s because the gateway runs close to its 500 m CPU limit
and cannot drain the queue after a short host stall. EXP-04 tests this by
changing only that limit. Memory is not varied: the gateway used about 48 Mi of
its 256 Mi limit in EXP-06.

### 10.1 Design

| Item          | Value                                                        |
| ------------- | ------------------------------------------------------------ |
| Configs       | c0-baseline, c5-gateway (500 m), c5-gateway-cpu1000 (1000 m) |
| Path          | `/health` only                                               |
| Levels        | 50 to 100 req/s in steps of 10; c0 and c5-gateway-cpu1000 also 120 and 150 |
| Run settings  | as EXP-02 (§9.1): 2 min, 30 s warm-up, 60 s cool-down        |
| Repetitions   | 3, interleaved over the three configurations                 |
| Monitoring    | `MONITOR=1` for every run                                    |

c5-gateway is measured again in the same session instead of reusing the EXP-02
runs, because the host was not equally fast between sessions (§9.4). c0 is
measured again for the same reason; it is the reference for the overhead. The
limit is raised to 1000 m and not further: the gateway runs as one uvicorn
process, which uses at most about one CPU core. The CPU request stays at 100 m.

Overlay: `kubernetes/overlays/kind-c5-gateway-cpu1000` (renders the same objects
as `kind-c5-gateway` except the CPU limit). Script: `scripts/measure-load.sh`
with `EXP=exp-04-gateway-cpu`; tables: `scripts/load_table.py`.
Results: `results/exp-04-gateway-cpu/`.

### 10.2 Hypotheses (stated before the runs)

* **H4.1 (collapse).** With 1000 m, the throttling of the `gateway` container
  stays below 50 % (maximum of the 1-minute windows) and no run collapses at 50
  to 100 req/s.
* **H4.2 (overhead).** Where the gateway is not throttled, the limit does not
  change the cost of a request: at 50 req/s the median overhead of both c5
  versions differs by less than 0.5 ms. Where the 500 m version is throttled,
  the 1000 m version has an equal or lower median overhead.

### 10.3 How the result is read

Runs are classified as in §9.6 (collapse, transient, stable), and throttling is
taken from cAdvisor as in §9.4.

* H4.1 holds if c5-gateway-cpu1000 has no collapsed run at 50 to 100 req/s and
  its gateway throttling stays below 50 % at those levels.
* If the 500 m version also has no collapsed run in this session, the collapse
  part cannot be decided; this is reported as such, and only throttling and
  median overhead are compared.
* With 3 runs per level a collapse is a rare event, so "no collapse" is weak
  evidence on its own. The throttling values are therefore part of the result,
  not only the collapse counts.

### 10.4 Results (20 Oct 2026, 3 repetitions, `MONITOR=1`)

66 runs, all valid (no pod restarts). Data: `results/exp-04-gateway-cpu/`;
tables: `load-summary.md` (`scripts/load_table.py`) and `throttling-summary.md`
(`scripts/throttle_table.py`). The terminal closed during repetition 2 of c0;
that block was deleted and run again completely, so every repetition of every
configuration is one uninterrupted block. Pilot: `results/exp-04-pilot/`
(1 run per level, not used for conclusions).

| Rate req/s | c0 median ms | Δ c5 500 m ms | Δ c5 1000 m ms | Gateway throttling max, 500 m | 1000 m |
| ---------- | ------------ | ------------- | -------------- | ----------------------------- | ------ |
| 50         | 2.08         | +2.20         | +2.05          | 0.3 %                         | 0.0 %  |
| 60         | 2.18         | +2.09         | +3.16          | 0.2 %                         | 0.2 %  |
| 70         | 2.45         | +1.85         | +2.56          | 1.4 %                         | 0.9 %  |
| 80         | 1.94         | +2.34         | +2.28          | 6.4 %                         | 0.2 %  |
| 90         | 1.93         | +2.39         | +2.26          | 18.6 %                        | 0.0 %  |
| 100        | 1.93         | +2.58         | +2.35          | 18.1 %                        | 0.0 %  |
| 120        | 1.86         | -             | +3.50          | -                             | 0.6 %  |
| 150        | 1.86         | -             | +3.21 (2 runs) | -                             | 1.3 %  |

Δ: median of the runs without collapse minus the c0 median (n = 3 unless
stated). Throttling: highest 1-minute value in any run of the level.

Collapsed runs at 50 to 100 req/s: none for c5 at 500 m (1 transient run at
100 req/s), none for c5 at 1000 m (1 transient run at 70 req/s). At 1000 m, 1 of
3 runs collapsed at 150 req/s. c0 had no collapse and 1 transient run (70 req/s).

**H4.1.** The throttling part is supported: with 1000 m the gateway was throttled
for at most 1.3 % of a 1-minute window up to 150 req/s. The collapse part cannot
be decided (§10.3): the 500 m version did not collapse in this session either;
its gateway was throttled for at most 18.6 %, against up to 100 % in EXP-02.

**H4.2.** Supported. At 50 req/s the median overhead of both versions differs by
0.15 ms. At 90 and 100 req/s, the levels at which the 500 m version was
throttled (mean 5.3 and 7.4 %), the 1000 m version is 0.13 and 0.23 ms lower. Not
predicted: at 60 and 70 req/s, where neither version was throttled, the 1000 m
version is 0.7 to 1.1 ms higher. Each of these levels contains one slow run
(average 9.50 and 20.97 ms), so the difference is not explained by the CPU limit.

**Together with EXP-02.** Collapse occurred only in runs in which the gateway was
heavily throttled (§9.6). Raising the limit removed the throttling at every
level and did not change the median cost per request. In this session the
500 m gateway was not pushed to its limit and no run collapsed, so the
experiment does not reproduce the EXP-02 collapses and cannot show whether
throttling causes the collapse or follows from the queue after a host stall.
What it does show: the per-request cost of the gateway does not depend on its
CPU limit, while the headroom does; with 500 m the gateway reached its limit
during bursts from about 80 req/s in this session.

**Limit at 150 req/s.** With 1000 m, one run collapsed at 150 req/s although the
gateway was throttled for only 0.9 % (it used 562 m on average). This collapse
is not caused by the CPU limit. Candidates are the single uvicorn process of the
gateway or the CPU of the host, which also runs k6; neither was measured here.

## 11. EXP-06 re-run on Kubernetes v1.36

EXP-07 runs on AKS, which no longer offers Kubernetes 1.31. To compare Kind and AKS
on the same Kubernetes minor version (RQ2), EXP-06 is repeated on Kind with
Kubernetes v1.36. The re-run is a new experiment with its own folder; the
original EXP-06 results stay unchanged.

### 11.1 What changed since EXP-06

| Item | EXP-06 (2026-10-08/09) | Re-run |
| ---- | ---------------------- | ------ |
| Kind / Kubernetes | v0.23.0 / v1.31.0 | v0.33.0 / v1.36.4 (node image pinned by digest) |
| Gateway placement | not pinned; scheduled on the inference node next to Ollama | pinned to the api node (fix in PR #27) |
| `llm-api` image | `llm-api:1.0.0`, built before 2026-10-08 | `llm-api:1.0.0`, digest `58870146…`, rebuilt 2026-10-15 from unchanged sources |

Unchanged: model `qwen2.5:0.5b` (ID `a8b0c5157701`), Ollama image digest, gateway
image `f6a6da4d…`, inference parameters, resource requests and limits, Calico,
Linkerd, Traefik and metrics-server versions, k6 scripts and the protocol below.
Every control was verified on v1.36.4 before the runs (EXP-05 re-run, 40 of 40
checks, `results/exp-05-security-verification/k8s-1.36/`).

### 11.2 Design

As EXP-06: all seven configurations, `/chat` (1 VU, 5 min measured, 2 min warm-up)
and `/health` (50 req/s, 2 min measured, 2 min warm-up), `MONITOR=0` as in EXP-06,
3 repetitions. The order of the configurations rotates per repetition:

| Repetition | Order |
| ---------- | ----- |
| 1 | c0 c1 c2 c3 c4 c5 c6 |
| 2 | c3 c4 c5 c6 c0 c1 c2 |
| 3 | c5 c6 c0 c1 c2 c3 c4 |

Command: `EXP=exp-06-k8s-1.36 make measure CONFIG=<config> REP=<n>`.
Results: `results/exp-06-k8s-1.36/`; tables: `scripts/overhead_table.py`.

### 11.3 Hypotheses (stated before the runs)

* **H6.1 (`/health`, verdicts).** Every configuration gets the same verdict as
  in EXP-06: C1 and C2 within noise; C3, C4, C5 and C6 distinct, higher.
* **H6.2 (`/health`, ranking).** The single controls keep their order of added
  latency: mTLS < TLS < gateway, and C6 adds more than any single control.
* **H6.3 (`/chat`).** No configuration is distinct, higher than the baseline;
  the cost of the controls stays hidden by inference.
* **H6.4 (resources).** On `/health`, C1 and C2 add no CPU or memory beyond a
  few millicores or MiB, and the gateway adds the most CPU of the single controls.

### 11.4 How the result is read

The verdict rule of §6 applies unchanged. Differences to EXP-06 are reported but
not attributed to one cause: the Kubernetes version and the gateway placement
changed together, so a difference between the two experiments cannot be
assigned to either alone. The re-run, not EXP-06, is the Kind reference for
EXP-07.

### 11.5 Results (15 Nov 2026, 3 repetitions, `MONITOR=0`)

42 runs, all valid (no pod restarts, no failed requests). Data:
`results/exp-06-k8s-1.36/`; table: `overhead-summary.md`
(`scripts/overhead_table.py`).

Deviations:

* The new cluster had no Gateway API CRDs: the pinned `linkerd-crds` chart
  2026.10.1 installs them only with `installGatewayAPI=true`, and
  `linkerd check --proxy` failed on this check when switching to c3 in
  repetition 1. The CRDs of the chart (bundle v1.1.1) were installed before
  c3 r1; c0, c1 and c2 of repetition 1 ran without them and do not use the mesh.
  `scripts/install-linkerd.sh` now sets the option.

`/health` (Δ avg against c0, ms; EXP-06 on v1.31 for comparison):

| Config | Δ ms | Δ % | Verdict | EXP-06 Δ ms |
| ------ | ---- | --- | ------- | ----------- |
| c1-rbac | +0.04 | +1.8 | within noise | +0.03 |
| c2-netpol | -0.01 | -0.5 | within noise | -0.01 |
| c3-mtls | +0.23 | +11.8 | distinct, higher | +0.36 |
| c4-tls | +0.73 | +36.7 | distinct, higher | +0.75 |
| c5-gateway | +2.20 | +110.6 | distinct, higher | +2.42 |
| c6-all | +4.39 | +220.9 | distinct, higher | +4.99 |

c0 average: 1.99 ms (EXP-06: 1.95 ms).

**H6.1.** Supported. Every configuration gets the same verdict as in EXP-06.

**H6.2.** Supported. mTLS (+0.23 ms) < TLS (+0.73 ms) < gateway (+2.20 ms);
C6 adds +4.39 ms.

**H6.3.** Supported. On `/chat` all configurations are within noise
(-2.7 % to +2.0 % against 1992.76 ms for c0).

**H6.4.** Supported. C1 and C2 change CPU by +2 and -0 m and memory by +1 and
-3 MiB. Of the single controls the gateway adds the most CPU (+122 m, against
+24 m for mTLS and +45 m for TLS).

**Against EXP-06.** The added latency of c3, c5 and c6 is 0.13 to 0.60 ms lower
than in EXP-06; c1, c2 and c4 differ by 0.02 ms or less. Following §11.4 this is
reported, not attributed to the Kubernetes version or the gateway placement.
