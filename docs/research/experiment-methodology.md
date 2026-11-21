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
| c0-baseline-r2, -r3 | kind-baseline-r2, -r3 | llm-baseline | http://localhost:8010 | no |
| c5-gateway-cpu1000-r2, -r3 | kind-c5-gateway-cpu1000-r2, -r3 | llm-c5-gateway | http://localhost:8010 | yes |
| c5-gateway-cpu1000-hpa | kind-c5-gateway-cpu1000-hpa | llm-c5-gateway | http://localhost:8010 | yes |

c5-gateway-cpu1000 exists only for EXP-04 (§10): it is c5-gateway with the gateway
CPU limit at 1000 m instead of 500 m and shares its namespace. The `-r2` and `-r3`
configurations exist only for EXP-03 (§12): the same overlays with 2 or 3
replicas of `fastapi` (c0) and of `gateway` and `fastapi` (c5); they share the
namespace of their 1-replica version. c5-gateway-cpu1000-hpa (§12.5) adds a
HorizontalPodAutoscaler to `gateway` and `fastapi`; switching to another
configuration of the namespace removes it again (`scripts/resume-env.sh`).

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

EXP-07 runs on managed clouds, which no longer offer Kubernetes 1.31. To compare
Kind and the managed clouds on the same Kubernetes minor version (RQ2), EXP-06 is repeated on Kind with
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

## 12. EXP-03 replicas

EXP-04 left one limit open (§10.4): with a 1000 m CPU limit the gateway was
hardly throttled, yet one of three runs at 150 req/s collapsed. Candidates are
the single uvicorn process of the gateway and the CPU of the host. EXP-03 adds a
second and a third replica of the services on the request path. If the single
process is the limit, more replicas remove it; if the host is the limit, they
do not. EXP-04 ran on Kubernetes v1.31 before the gateway was pinned to the api
node; EXP-03 measures the 1-replica versions again in the same session on
v1.36.4, so its comparison does not depend on the EXP-04 numbers.

### 12.1 Design

| Item          | Value                                                              |
| ------------- | ------------------------------------------------------------------ |
| Configs       | c0-baseline, -r2, -r3; c5-gateway-cpu1000, -r2, -r3               |
| Replicas      | 1, 2 or 3 of `fastapi` (c0); 1, 2 or 3 of `gateway` and of `fastapi` (c5) |
| Path          | `/health` only                                                     |
| Levels        | 100, 150, 200 req/s                                                |
| Run settings  | as EXP-02 (§9.1): 2 min, 30 s warm-up, 60 s cool-down              |
| Repetitions   | 3, interleaved; the start configuration moves by two per repetition |
| Monitoring    | `MONITOR=1` for every run                                          |

Order per repetition (c5 = c5-gateway-cpu1000):
r1 c0, c0-r2, c0-r3, c5, c5-r2, c5-r3; r2 c0-r3, c5, c5-r2, c5-r3, c0, c0-r2;
r3 c5-r2, c5-r3, c0, c0-r2, c0-r3, c5. All six configurations are measured in
the same session, so the comparison does not depend on the host speed of
another day (§9.4).

Ollama stays at one replica (its volume is ReadWriteOnce, and `/health` does not
reach it). All replicas of a Deployment run on the same Kind node (`role=api`,
`kind-placement`); all Kind nodes share the 8 CPUs of the host with k6, so the
placement does not limit the CPU available to a replica. kube-proxy spreads
connections, not single requests, over the replicas; k6 keeps one connection
per VU open.

New in this experiment, `scripts/run-experiment.sh` records the CPU use of the
whole host (the WSL VM with the Kind nodes and k6) during the measured run from
`/proc/stat` (`host_cpu=` in the `.meta.txt`: busy and steal share of all CPUs).
`scripts/resume-env.sh` now sets the replica count given by the overlay instead
of always 1. CPU and memory per Deployment are the sum over its replicas
(`scripts/overhead_table.py`); throttling is the share of throttled periods over
all replicas of a container (`scripts/throttle_table.py`).

Pilot: one run per level of every configuration in `results/exp-03-pilot/`,
to check the replica switch, the host CPU record and the run time; not used for
conclusions. Script: `scripts/measure-load.sh` with `PATHS=health`,
`RATES="100 150 200"` and `EXP=exp-03-replicas`; tables: `scripts/load_table.py`
and `scripts/throttle_table.py`. Results: `results/exp-03-replicas/`.

An autoscaling part (HorizontalPodAutoscaler on `gateway` and `fastapi`) follows
as its own design with hypotheses before its runs.

### 12.2 Hypotheses (stated before the runs)

* **H3.1 (capacity).** The limit of the 1000 m gateway at 150 req/s comes from
  the single gateway process. With 2 replicas, c5 has no collapsed run at 150
  and 200 req/s.
* **H3.2 (cost per request).** At 100 req/s, where no configuration is expected
  to saturate, 2 or 3 replicas change the median latency by less than 0.5 ms
  against 1 replica, both for c0 and for c5.
* **H3.3 (resources).** At 100 req/s every added replica adds about one pod's
  memory per Deployment (about 50 Mi each) and changes the total CPU of the
  request path by less than 20 %.
* **H3.4 (third replica).** A third replica adds nothing measurable to the
  second: at 150 and 200 req/s c5-r3 has no fewer collapsed runs than c5-r2,
  and its median latency differs by less than 0.5 ms, because all replicas share
  the host CPUs with k6.

### 12.3 How the result is read

Runs are classified as in §9.6; throttling and host CPU come from
`scripts/throttle_table.py`.

* H3.1 holds if c5-gateway-cpu1000-r2 has no collapsed run at 150 and 200 req/s.
* If c5-gateway-cpu1000 (1 replica) has no collapsed run at 150 and 200 req/s
  either, the capacity part cannot be decided (as in §10.3); only latency,
  throttling and host CPU are compared.
* If every c5 version collapses at 200 req/s and the host was at least 90 % busy
  in those runs, the limit is the host, not the number of replicas; this is
  reported as such.
* With 3 runs per level a collapse is rare, so host CPU, throttling and the
  number of transient runs are part of the result, not only the collapse counts.

### 12.4 Results (2026-11-16)

54 runs, all valid (no pod restarts), 3 h 19 min in one session. Data:
`results/exp-03-replicas/`; tables: `load-summary.md` (`scripts/load_table.py`)
and `throttling-summary.md` with the host CPU (`scripts/throttle_table.py`).
Pilot: `results/exp-03-pilot/` (1 run per level, not used for conclusions).

Median latency of the runs without collapse (ms, n = 3):

| Rate req/s | c0 | c0-r2 | c0-r3 | c5 | c5-r2 | c5-r3 |
| ---------- | ---- | ----- | ----- | ---- | ----- | ----- |
| 100        | 1.79 | 2.04  | 1.82  | 4.11 | 4.19  | 4.18  |
| 150        | 1.71 | 1.81  | 1.81  | 4.12 | 4.28  | 4.26  |
| 200        | 1.64 | 1.76  | 1.77  | 4.36 | 4.38  | 4.48  |

c5 = c5-gateway-cpu1000. No run collapsed. Two runs were transient: c5 at
200 req/s (repetition 1, 46 requests dropped, average 38.11 ms, slowest request
3.27 s) and c5-r2 at 100 req/s (repetition 2, 31 dropped, average 11.21 ms,
slowest 1.45 s). The gateway was throttled for at most 0.7 % of a 1-minute
window (c5, 200 req/s), `fastapi` for at most 0.2 %. The host was at most
31.1 % busy in any run (c5-r3, 200 req/s), with no steal time.

**H3.1.** Cannot be decided (§12.3). c5-r2 had no collapsed run at 150 and
200 req/s, but c5 with one replica had none either; its only sign of a limit is
the transient run at 200 req/s. The collapse at 150 req/s in EXP-04 did not
recur.

**H3.2.** Supported. At 100 req/s, 2 and 3 replicas change the median by
+0.25 and +0.03 ms for c0 and by +0.08 and +0.07 ms for c5.

**H3.3.** Supported. At 100 req/s every added replica adds 42 to 52 Mi per
Deployment (`fastapi` in c0: 53, 100, 142 Mi; in c5: 46, 98, 148 Mi; `gateway`:
48, 93, 139 Mi). The total CPU of the request path changes by 0 and -8 % for c0
(202, 202, 186 m) and by +6 and +5 % for c5 (438, 464, 461 m).

**H3.4.** The prediction holds, the stated reason does not. At 150 and
200 req/s neither c5-r2 nor c5-r3 had a collapsed run, and their medians differ
by 0.02 and 0.10 ms. The host was at most 31.1 % busy, so the shared host CPU
did not limit the third replica; no limit was reached at all.

**Post-hoc: spread over the replicas.** k6 opens one connection per VU, which
kube-proxy spreads over the `gateway` replicas; in each run the busiest gateway
pod used at most 1.5 times the CPU of the least busy one. The gateway keeps its
own few connections to `fastapi` open, so behind the gateway the spread is
uneven: with 3 replicas, one `fastapi` pod used 4 m (idle) in all three runs at
100 req/s and 9 and 15 m in two of three runs at 200 req/s; with 2 replicas, one
`fastapi` pod used 20 m in one run at 200 req/s. Without the gateway (c0), k6
reaches `fastapi` directly and no replica was idle (lowest 39 m at 100 req/s).
Values: `*.resources.txt`.

**Post-hoc: CPU at 200 req/s.** Outside the tested level of H3.3, c0-r2 used
21 % more `fastapi` CPU than c0 at 200 req/s (396 against 327 m); c5-r2 and
c5-r3 used 7 and 13 % more on the request path (986 and 1041 against 921 m).

**Together with EXP-04.** Up to 200 req/s, one replica of each service with a
1000 m gateway kept up in 8 of 9 runs and never collapsed; with 2 and 3 replicas
no run at 150 or 200 req/s dropped a request (one c5-r2 run at 100 req/s did).
More replicas did not change the cost per request (H3.2) and added about 50 Mi
per replica (H3.3). In this session neither the replica count nor the host CPU
was the limit, so the experiment does not explain the single collapse at 150
req/s in EXP-04. The per-request overhead of the gateway (2.3 to 2.8 ms over c0
in the medians) does not depend on the number of replicas.

### 12.5 Autoscaling part: design (stated before the runs)

§12.4 compared fixed replica counts at constant rates. The autoscaling part
asks what a HorizontalPodAutoscaler (HPA) does when the load changes during a
run: how fast it adds replicas, whether that changes latency, and whether the
added replicas receive traffic.

| Item          | Value                                                              |
| ------------- | ------------------------------------------------------------------ |
| Configs       | c5-gateway-cpu1000 (1 replica), -r3 (3 replicas), -hpa (1 to 3)    |
| HPA           | `gateway` and `fastapi`, min 1, max 3, target 200 m average CPU per pod, scale-down window 60 s |
| Load          | `/health`, `tests/k6/health-step.js`: 20 req/s for 3 min, 10 s ramp, 200 req/s for 5 min, 10 s ramp, 20 req/s for 4 min (12 min 20 s) |
| Warm-up       | 30 s at 20 req/s (`tests/k6/health-path.js`), discarded            |
| Repetitions   | 3, interleaved: r1 1, r3, hpa; r2 r3, hpa, 1; r3 hpa, 1, r3        |
| Start state   | every run starts at the replica count of its overlay (the script waits up to 5 min) |
| Monitoring    | `MONITOR=1` for every run                                          |

The target is an absolute CPU value because the CPU requests differ (gateway
100 m, `fastapi` 500 m); the CPU limits are unchanged. The scale-down window is
shortened from the default 300 s so that scale-in happens inside the run.
Kind defaults are kept for the rest: metrics-server at 15 s resolution, HPA
sync every 15 s. Basis for the expected replica counts (§12.4, 1 replica at
200 req/s): `gateway` used 618 m and `fastapi` 303 m, so the HPA should ask for
4 (capped at 3) gateway pods and 2 `fastapi` pods; at 20 req/s both stay
below 200 m.

The k6 script tags every request with its phase: `pre` (0-180 s), `surge`
(180-250 s: ramp and the first 60 s at 200 req/s), `high` (250-490 s) and
`post` (490-740 s), and writes latency per phase into the summary JSON.
`scripts/measure-hpa.sh` records the ready and desired replicas of `gateway`
and `fastapi` every 5 s (`*.replicas.txt`); CPU per pod (`*.resources.txt`),
throttling and host CPU are recorded as in §12.1. Times are counted from
`start=` in the `.meta.txt`.

Command: `EXP=exp-03-hpa make measure-hpa CONFIG=<config> REP=<n>`. Pilot: one
run of c5-gateway-cpu1000-hpa and one of c5-gateway-cpu1000 in
`results/exp-03-hpa-pilot/`, to check the phase tags, the replica record and
the run time; not used for conclusions. Results: `results/exp-03-hpa/`. The
table script for this part is written with the results.

### 12.6 Autoscaling part: hypotheses (stated before the runs)

* **H3.5 (scale-out).** In every HPA run, `gateway` has at least 2 ready
  replicas within 90 s after the step (by 270 s) and 3 before the end of the
  high phase (490 s); `fastapi` reaches 2 and not 3.
* **H3.6 (latency).** Because one replica kept up with 200 req/s (§12.4), the
  HPA does not change latency: in the surge and high phases the median of
  c5-gateway-cpu1000-hpa is within 0.5 ms of both fixed configurations, and no
  run of any configuration collapses (§9.6).
* **H3.7 (traffic on new replicas).** k6 keeps the connections it opened in the
  low phase, and kube-proxy spreads connections, not requests. In the high
  phase, the gateway pods added by the HPA together use less CPU than the pod
  that existed at the start of the run.
* **H3.8 (scale-in).** After the drop to 20 req/s (500 s), both Deployments are
  back at 1 replica within 180 s (by 680 s), inside the run.

### 12.7 Autoscaling part: how the result is read

* Scale-out and scale-in times come from `*.replicas.txt` (5 s resolution, so
  ±5 s). A time counts for H3.5 and H3.8 only if all three HPA runs meet it.
* H3.7 uses the mean CPU per pod in the high phase from `*.resources.txt`; the
  first pod is the one present in the first sample of the run.
* If the HPA does not scale out at all, H3.5 does not hold and H3.6 and H3.7
  cannot be tested; this is reported with the HPA events of the run
  (`*.hpa.txt`).

### 12.8 Autoscaling part: results (2026-11-16)

9 runs, all valid (no pod restarts), in one session; the host was at most
21.4 % busy, with no steal time. Data: `results/exp-03-hpa/`; tables:
`hpa-summary.md` (`scripts/hpa_table.py`, written after the runs as stated in
§12.5) and `throttling-summary.md` (`scripts/throttle_table.py`, which now also
reads the load-step runs; throttling is over all replicas of a container).
Pilot: `results/exp-03-hpa-pilot/` (not used for conclusions). Each run started
after a short wait for the lock: the replica sampler of the previous run still
held it for up to 5 s. This did not overlap any measurement; the sampler now
closes the lock descriptor.

Median latency per phase (ms, median of the three run medians):

| Config | pre | surge | high | post | Runs: stable / transient / collapse |
| ------ | ---- | ----- | ------- | ---- | ----------------------------------- |
| c5 (1 replica)  | 4.50 | 4.98 | 5.11    | 4.55 | 0 / 2 / 1 |
| c5-r3 (3)       | 4.42 | 4.63 | 4.68    | 4.44 | 3 / 0 / 0 |
| c5-hpa (1 to 3) | 4.49 | 7.12 | 3452.50 | 4.64 | 0 / 0 / 3 |

All three HPA runs collapsed: 47 to 53 % of the requests were dropped, and the
high-phase median was 2931 to 3454 ms. With one fixed replica, one run
collapsed (repetition 1, 11 % dropped; high-phase median 5.19 ms) and two were
transient (20 and 40 dropped). With three fixed replicas no request was
dropped and no request took longer than 274 ms. The highest 1-minute gateway
throttling was 48.0 % with one fixed replica, 34.4 % with the HPA and 0.0 % with
three replicas.

| HPA run | gateway at 3 ready | `fastapi` at 2 ready | `fastapi` back to 1 | all back to 1 | gateway CPU, high phase: pod at start / added pods |
| ------- | ------------------ | -------------------- | ------------------- | ------------- | -------------------------------------------------- |
| r1      | 231 s | 238 s | 307 s | 595 s | 995 / 4 m |
| r2      | 234 s | 245 s | 315 s | 581 s | 992 / 4 m |
| r3      | 222 s | 228 s | 285 s | 569 s | 996 / 4 m |

Times in seconds after the start of the run; the step to 200 req/s begins at
180 s, the drop to 20 req/s ends at 500 s. With one and three fixed replicas
the gateway used 726 to 746 m and 704 to 714 m (sum) in the high phase.

**H3.5.** Supported. The HPA asked for 3 gateway pods 30 to 42 s after the step;
all three were ready 42 to 54 s after it. `fastapi` reached 2 and not 3.

**H3.6.** Not supported. The HPA did not leave latency unchanged: all three HPA
runs collapsed in the high phase, while three fixed replicas stayed stable.
One fixed replica collapsed in one of three runs.

**H3.7.** Supported, more strongly than stated. In the high phase the two
gateway pods added by the HPA used 4 m together, the pod that existed at the
start 992 to 996 m, that is, its CPU limit of 1000 m.

**H3.8.** Supported. Both Deployments were back at 1 replica 69 to 95 s after
the drop (by 569 to 595 s).

**Post-hoc: what happened.** The added gateway pods were ready but received
almost no requests, so the whole load stayed on one pod. That pod reached its
CPU limit, was throttled, and the queue did not drain until the load dropped.
Because fewer requests got through, `fastapi` used less CPU and the HPA scaled
it back to 1 replica while the load was still high (285 to 315 s). With one
fixed replica the same pod ran at about 730 m and kept up in two of three runs;
in the HPA runs it ran at its limit in every run. The recorded data does not
show why the pod at start used more CPU in the HPA runs, or why no new
connection reached the added pods; both are open.

**Together with §12.4.** Replicas that exist before the load arrives share it
and remove the limit (c5-r3: no dropped request). Replicas that an HPA adds
during the load step did not take load from the client's existing connections
and did not prevent collapse; in this setup scaling out reacted in under a
minute but did not help. For the thesis this means: on the request path
behind the API gateway, capacity has to be in place before a load step;
CPU-based autoscaling alone did not provide it for a client that keeps its
connections open.

## 13. EXP-01 re-run on Kubernetes v1.36

EXP-01 (2026-10-06) gave the reference values of the unsecured stack on
Kubernetes v1.31: `/chat` latency and tokens per second, `/health` latency, and
the CPU and memory of `fastapi` and Ollama. EXP-07 compares Kind and managed
clouds on v1.36, so EXP-01 is repeated on the v1.36.4 cluster with its own protocol. The
re-run is a new experiment with its own folder; the EXP-01 results stay
unchanged.

### 13.1 What changed since EXP-01

As §11.1 (Kind v0.33.0 with Kubernetes v1.36.4, `llm-api` rebuilt from
unchanged sources, digest `58870146…`). The gateway placement does not matter
here: c0 has no gateway. New since EXP-01: the measurement lock and the host CPU
record (`host_cpu=` in the `.meta.txt`), neither of which changes what k6
measures. Unchanged: model `qwen2.5:0.5b` (ID `a8b0c5157701`), Ollama image
digest, inference parameters, resource requests and limits, k6 scripts.

### 13.2 Design

As EXP-01: c0-baseline only, `/chat` (1 VU, 5 min measured) and `/health`
(50 req/s, 2 min measured), each with 1 min warm-up and 2 min cool-down
(protocol of §4), `MONITOR=0`, 3 repetitions. EXP-01 ran the three `/chat` runs
first and then the three `/health` runs; the re-run alternates them per
repetition (`scripts/measure-config.sh`), which only changes the order.

Command: `EXP=exp-01-k8s-1.36 WARMUP=1m make measure CONFIG=c0-baseline REP=<n>`
for n = 1, 2, 3. Results: `results/exp-01-k8s-1.36/`; table:
`scripts/summarize_results.py` (includes tokens per second). No pilot: the
configuration, scripts and settings are the ones of EXP-01 and EXP-06 re-run.

### 13.3 Hypotheses (stated before the runs)

* **H1.1 (`/chat`).** Average latency and tokens per second differ from EXP-01
  (2001.20 ms, 19.99 tokens/s) by less than 5 %.
* **H1.2 (`/health`).** Average latency differs from EXP-01 (1.97 ms) by less
  than 0.3 ms.
* **H1.3 (resources).** CPU of Ollama during `/chat` and of `fastapi` during
  `/health` differ from EXP-01 (1649 m and 87 m) by less than 10 %.

### 13.4 How the result is read

Values are means over the three repetitions with their min-max range, as in the
EXP-01 summary. A hypothesis holds if the mean of the re-run is within the
stated distance of the EXP-01 mean. As in §11.4, a difference is reported but
not assigned to one cause, since the Kubernetes version, the Kind version and
the image build changed together. The c0 runs of the EXP-06 re-run (§11.5),
taken with a 2 min warm-up, are a second v1.36.4 reference and are compared
post-hoc.

### 13.5 Results (17 Nov 2026, 3 repetitions, `MONITOR=0`)

6 runs, all valid (no pod restarts), 00:21 to 00:58 UTC. Data:
`results/exp-01-k8s-1.36/`; table: `summary.md` (`scripts/summarize_results.py`).
The host was 32.5 to 34.5 % busy during `/chat` and 9.4 to 12.5 % during
`/health`, with no steal time.

| Value | EXP-01 (v1.31) | Re-run (v1.36.4) | Difference |
| ----- | -------------- | ---------------- | ---------- |
| `/chat` average | 2001.20 ms | 2020.13 ms (1982.74-2092.73) | +0.9 % |
| Tokens per second | 19.99 | 19.90 (19.32-20.21) | -0.5 % |
| `/health` average | 1.97 ms | 1.96 ms (1.94-1.98) | -0.01 ms |
| Ollama CPU, `/chat` | 1649 m | 1678 m (1669-1694) | +1.8 % |
| `fastapi` CPU, `/health` | 87 m | 88 m (86-90) | +1.1 % |

**H1.1.** Supported: `/chat` latency +0.9 %, tokens per second -0.5 %. The
first `/chat` run was the slowest (average 2092.73 ms, slowest request
4384 ms); without it the range is 1982.74 to 1984.91 ms.

**H1.2.** Supported: the `/health` average differs by 0.01 ms.

**H1.3.** Supported: Ollama CPU +1.8 %, `fastapi` CPU +1.1 %.

**Post-hoc: memory.** Not part of a hypothesis. Memory was higher than in
EXP-01: Ollama 691 against 647 Mi, `fastapi` 62 against 47 Mi during `/health`.

**Post-hoc: EXP-06 re-run.** The c0 runs of the EXP-06 re-run (§11.5, 2 min
warm-up) gave 1992.76 ms and 20.11 tokens per second on `/chat`, 1.99 ms on
`/health`, and 1665 m (Ollama) and 88 m (`fastapi`) of CPU; all within the
distances of H1.1 to H1.3 from this re-run as well.

The unsecured stack performs the same on Kubernetes v1.36.4 as on v1.31 within
these margins, so the v1.36.4 values can stand in for EXP-01 as the Kind
reference for EXP-07.

## 14. EXP-02 re-run on Kubernetes v1.36

EXP-02 (2026-10-17) measured how the overhead of the gateway (c5) and of all
controls (c6) behaves when the load rises, on Kubernetes v1.31. It is repeated
on the v1.36.4 cluster with its own protocol, so that the load behaviour that
EXP-07 is compared against comes from the same Kubernetes version. The re-run is
a new experiment with its own folder; the EXP-02 results stay unchanged.

### 14.1 What changed since EXP-02

As §11.1: Kind v0.33.0 with Kubernetes v1.36.4, `llm-api` rebuilt from unchanged
sources, and the gateway pinned to the api node (in EXP-02 it ran on the
inference node next to Ollama). New since EXP-02: the measurement lock and the
host CPU record (`host_cpu=`). Unchanged: model, Ollama and gateway images,
inference parameters, resource requests and limits (gateway 500 m), k6 scripts.

### 14.2 Design

As EXP-02 (§9.1): `/health` on c0-baseline, c5-gateway and c6-all at 50, 60, 70,
80, 90 and 100 req/s (c0 also 150 and 200), `/chat` on c0-baseline and c6-all at
1, 2 and 4 VUs; same run settings, `MONITOR=1`, 3 repetitions. The start
configuration rotates per repetition: r1 c0, c5, c6; r2 c5, c6, c0; r3 c6, c0,
c5. 78 runs, about 6 h.

Command: `EXP=exp-02-k8s-1.36 MONITOR=1 ./scripts/measure-load.sh <config> <n>`,
with `RATES="50 60 70 80 90 100 150 200"` for c0 and `PATHS=health` for c5.
Results: `results/exp-02-k8s-1.36/`; tables: `scripts/load_table.py` and
`scripts/throttle_table.py` (throttling and host CPU per run). No pilot: levels
and settings are those of EXP-02.

### 14.3 Hypotheses (stated before the runs)

* **H2.3 (`/chat`).** As in EXP-02: throughput levels off from 2 VUs, and c0 and
  c6 overlap at every level. At 2 and 4 VUs the throughput of each configuration
  is within 10 % of EXP-02 (0.42 to 0.43 req/s for c0, 0.45 to 0.46 for c6).
* **H2.4 (`/health`, overhead).** From 50 to 90 req/s the median overhead
  (runs without collapse) is between +2 and +4 ms for c5 and between +4 and
  +7 ms for c6 at every level, as in EXP-02 (+2.66 to +3.38 and +5.33 to
  +6.92 ms).
* **H2.5 (`/health`, collapse).** c0 has no collapsed run up to 200 req/s. Every
  collapsed run of c5 or c6 is a run in which the gateway container was
  throttled for at least 50 % of a 1-minute window, as all five collapsed runs
  of EXP-02 were.

### 14.4 How the result is read

Runs are classified as in §9.6; the rule of §9.3 is reported as well. As in
§11.4, differences to EXP-02 are reported but not assigned to one cause: the
Kubernetes version, the Kind version and the gateway placement changed
together. If no run collapses, the second part of H2.5 cannot be tested; the
throttling of the gateway per level is reported instead.

### 14.5 Results (17 Nov 2026, 3 repetitions, `MONITOR=1`)

78 runs, all valid (no pod restarts), 01:19 to 06:48 UTC. Data:
`results/exp-02-k8s-1.36/`; tables: `load-summary.md` (`scripts/load_table.py`)
and `throttling-summary.md` with the host CPU (`scripts/throttle_table.py`). The
host was at most 23.9 % busy during `/health` runs and at most 38.2 % during
`/chat` runs, with no steal time.

**`/chat` (H2.3).**

| VUs | c0 req/s (EXP-02) | c6 req/s (EXP-02) | c0 avg ms (runs) | c6 avg ms (runs) |
| --- | ----------------- | ----------------- | ---------------- | ---------------- |
| 1   | 0.334 (0.289)     | 0.325 (0.300)     | 1997.59 (1958.91-2046.68) | 2088.90 (1946.29-2365.04) |
| 2   | 0.477 (0.421)     | 0.453 (0.446)     | 3166.87 (3045.91-3242.96) | 3412.06 (3059.47-3811.87) |
| 4   | 0.483 (0.430)     | 0.460 (0.457)     | 7145.48 (6951.10-7279.21) | 7605.61 (7033.82-8713.20) |

Partly supported. Throughput levels off from 2 VUs, and c0 and c6 overlap at
every level. c6 is within 2 % of EXP-02 at 2 and 4 VUs; c0 is 13 and 12 %
higher, outside the stated 10 %. In EXP-02 c0 was slower than in EXP-01 at
1 VU (2596.50 against 2001.20 ms); the re-run is close to EXP-01 and to the
EXP-01 re-run (§13.5).

**`/health`.** Median of the runs without collapse, overhead against c0 (ms):

| Rate req/s | c0 median | Δ c5 | Δ c6 | Δ c5 EXP-02 | Δ c6 EXP-02 |
| ---------- | --------- | ----- | ----- | ----------- | ----------- |
| 50         | 1.89      | +2.64 | +3.97 | +3.38       | +5.62       |
| 60         | 1.85      | +2.77 | +4.67 | +2.81       | +5.45       |
| 70         | 1.80      | +2.96 | +4.15 | +2.66       | +6.92       |
| 80         | 1.78      | +2.99 | +4.88 | +3.27       | +5.87       |
| 90         | 1.75      | +3.10 | +5.08 | +3.05       | +5.33       |
| 100        | 1.71      | +2.62 (2 runs) | +4.35 | +3.00 (2 runs) | n/a |

**H2.4.** Not supported, by a small margin: c5 is between +2.64 and +3.10 ms at
50 to 90 req/s as predicted, and c6 between +4.15 and +5.08 ms from 60 to
90 req/s, but at 50 req/s c6 is +3.97 ms, 0.03 ms below the stated range. The
c6 overhead is lower than in EXP-02 at every level from 50 to 90 req/s, by 0.25
to 2.77 ms.

**H2.5.** The first part is supported: c0 had no collapsed run up to 200 req/s
(no dropped request at all). The second part is not: one run collapsed (c5,
100 req/s, repetition 2, 356 requests dropped, 3.0 %) while the gateway was
throttled for at most 21.7 % of a 1-minute window (mean 6.6 %). The only other
run with drops was transient (c6, 90 req/s, repetition 3, 62 dropped, gateway
throttling at most 21.6 %). The highest gateway throttling of the whole re-run
was 21.7 %, against up to 100 % in EXP-02.

**Post-hoc: gateway CPU.** The gateway in c5 used 147 to 309 m from 50 to
100 req/s, against 196 to 384 m in EXP-02; it stayed further from its 500 m
limit, which fits the lower throttling. The gateway now runs on the api node
instead of next to Ollama, but this experiment cannot separate that from the
other changes (§14.4).

**Together with EXP-02.** On v1.36.4 the security path collapsed in 1 of 36
gateway runs (EXP-02: 5), and the one collapse happened without heavy gateway
throttling. Heavy throttling is therefore not necessary for a collapse in this
setup; with only one such run, the cause stays open, as in §10.4 and §12.4.
The overhead per request of the gateway is stable at about +3 ms up to
90 req/s in both experiments.

## 15. EXP-04 re-run on Kubernetes v1.36

EXP-04 (2026-10-20) compared the gateway with a 500 m and a 1000 m CPU limit on
Kubernetes v1.31. It is repeated on the v1.36.4 cluster with its own protocol,
so that every Kind experiment that EXP-07 refers to exists on the same
Kubernetes version. The re-run is a new experiment with its own folder; the
EXP-04 results stay unchanged.

### 15.1 What changed since EXP-04

As §14.1: Kind v0.33.0 with Kubernetes v1.36.4, `llm-api` rebuilt from unchanged
sources, the gateway pinned to the api node, the measurement lock and the host
CPU record. Unchanged: images, model, inference parameters, the two gateway
limits (500 m and 1000 m), all other requests and limits, k6 scripts.

### 15.2 Design

As EXP-04 (§10.1): `/health` on c0-baseline, c5-gateway (500 m) and
c5-gateway-cpu1000 (1000 m) at 50, 60, 70, 80, 90 and 100 req/s, c0 and
c5-gateway-cpu1000 also at 120 and 150 req/s; run settings as EXP-02 (2 min,
30 s warm-up, 60 s cool-down), `MONITOR=1`, 3 repetitions. The start
configuration rotates per repetition: r1 c0, 500 m, 1000 m; r2 500 m, 1000 m,
c0; r3 1000 m, c0, 500 m. 66 runs, about 4 h.

Command: `EXP=exp-04-k8s-1.36 MONITOR=1 PATHS=health ./scripts/measure-load.sh
<config> <n>`, with `RATES="50 60 70 80 90 100 120 150"` for c0 and
c5-gateway-cpu1000. Results: `results/exp-04-k8s-1.36/`; tables:
`scripts/load_table.py` and `scripts/throttle_table.py`. No pilot: levels and
settings are those of EXP-04.

### 15.3 Hypotheses (stated before the runs)

* **H4.3 (1000 m).** The gateway with 1000 m is throttled for less than 5 % of
  any 1-minute window up to 150 req/s, and none of its runs collapses at 50 to
  100 req/s (EXP-04: at most 1.3 %; EXP-03 on v1.36.4: at most 0.7 %).
* **H4.4 (cost per request).** As H4.2: at 50 req/s the median overhead of the
  two versions differs by less than 0.5 ms, and at 90 and 100 req/s the 1000 m
  version has an equal or lower median overhead than the 500 m version.
* **H4.5 (500 m).** The gateway with 500 m is throttled more at 100 than at
  50 req/s, with a 1-minute maximum at 100 req/s between 5 and 50 % (EXP-04:
  18.1 %; EXP-02 re-run: 21.7 %).

### 15.4 How the result is read

Runs are classified as in §9.6 and throttling is read as in §10.3. If neither
version collapses, the collapse part of H4.3 counts as met but says little
(§10.3); throttling and median overhead carry the result. As in §11.4,
differences to EXP-04 are reported but not assigned to one cause.

### 15.5 Results (17 Nov 2026, 3 repetitions, `MONITOR=1`)

66 runs, all valid (no pod restarts), 19:16 to 23:14 UTC. Data:
`results/exp-04-k8s-1.36/`; tables: `load-summary.md` (`scripts/load_table.py`)
and `throttling-summary.md` with the host CPU (`scripts/throttle_table.py`).
The host was at most 22.7 % busy, with no steal time. No run dropped a request:
all 66 runs are stable (§9.6).

| Rate req/s | c0 median ms | Δ c5 500 m ms | Δ c5 1000 m ms | Gateway throttling max, 500 m | 1000 m |
| ---------- | ------------ | ------------- | -------------- | ----------------------------- | ------ |
| 50         | 1.92         | +2.03         | +2.00          | 0.0 %                         | 0.0 %  |
| 60         | 1.84         | +2.12         | +2.08          | 0.0 %                         | 0.0 %  |
| 70         | 1.79         | +2.06         | +2.08          | 0.0 %                         | 0.0 %  |
| 80         | 1.79         | +2.06         | +2.11          | 0.5 %                         | 0.0 %  |
| 90         | 1.74         | +2.16         | +2.12          | 5.2 %                         | 0.0 %  |
| 100        | 1.71         | +2.24         | +2.15          | 14.1 %                        | 0.0 %  |
| 120        | 1.67         | -             | +2.17          | -                             | 0.2 %  |
| 150        | 1.57         | -             | +2.33          | -                             | 0.9 %  |

Δ: median of the runs minus the c0 median (n = 3). Throttling: highest
1-minute value in any run of the level.

**H4.3.** Supported: with 1000 m the gateway was throttled for at most 0.9 %
(150 req/s), and no run collapsed. As no run of the 500 m version collapsed
either, the collapse part carries little weight (§15.4).

**H4.4.** Supported. At 50 req/s the two versions differ by 0.03 ms; at 90 and
100 req/s the 1000 m version is 0.04 and 0.09 ms lower.

**H4.5.** Supported: the 500 m gateway was not throttled at 50 req/s and at
most 14.1 % at 100 req/s. It used 147 to 291 m from 50 to 100 req/s, the
1000 m version 136 to 263 m.

**Together with EXP-04.** In EXP-04 one run of the 1000 m version collapsed at
150 req/s and three runs were transient (one per configuration); in the re-run no run dropped a request,
up to 150 req/s, matching EXP-03 on v1.36.4 (§12.4). The overhead of the
gateway is +2.00 to +2.33 ms at every level and does not depend on the limit
(EXP-04: +2.05 to +3.50 ms). On v1.36.4 the 500 m limit leaves enough headroom
up to 100 req/s in this session; the limit shows only as moderate throttling
at 90 and 100 req/s.

## 16. EXP-07 on managed clouds

EXP-07 repeats the EXP-06 re-run (§11) on managed Kubernetes services to answer
RQ2: does the deployment environment change the overhead of the controls? Four
platforms are planned: Google Kubernetes Engine (GKE), Amazon Elastic
Kubernetes Service (EKS), OVHcloud Managed Kubernetes Service (MKS) and Azure
Kubernetes Service (AKS). The Kind reference is the set of v1.36.4 re-runs
(§11.5, §13.5, §14.5, §15.5). Results are reported per platform; absolute
latencies are not compared as a cost of a control.

### 16.1 What stays the same on every platform

Model `qwen2.5:0.5b` (ID `a8b0c5157701`), Ollama image digest, the `llm-api` and
`llm-gateway` images used on Kind (pushed unchanged to GitHub Container Registry
and pulled by their manifest digests `58870146…` and `f6a6da4d…`, the same as on
Kind; verified on the nodes by config digest), inference parameters, resource
requests and limits, the objects of overlays c0 to c6 (the `cloud-*` overlays
differ from the `kind-*` overlays only in the image reference), Linkerd and
Traefik chart versions, k6 version and scripts, and the run protocol (§4).
Every platform has two worker nodes labelled `role=inference` and `role=api`,
each with 4 vCPU and 16 GiB (x86-64). k6 runs on a separate VM with 4 vCPU in
the same region and network. On that VM, `scripts/cloud-entry.sh` maps
`localhost:8010`, `:8080` and `:8443` in the kernel to NodePort 30010 and to
Traefik's host ports 8000 and 443 on the `role=api` node (8000 instead of 80,
which EKS reserves on every node), as Docker maps them to
the Kind node; URLs, the ingress host and the TLS certificate therefore stay as
on Kind. No cloud load balancer is in the measured path.

### 16.2 What differs between platforms (recorded per run in `*-environment.txt`)

| Item | Kind re-run | GKE | EKS | OVH MKS | AKS |
| ---- | ----------- | --- | --- | ------- | --- |
| Cluster | 3 Docker nodes on one WSL2 host | Standard, zonal | managed control plane | managed control plane (free tier) | managed control plane |
| CNI | Calico v3.32.2 | GKE default | Amazon VPC CNI | Canal | Azure CNI Overlay |
| NetworkPolicy engine | Calico | Calico if offered for the cluster version, otherwise Dataplane V2 (Cilium) | Calico, policy only | Calico (Canal) | Calico |
| Node CPUs | shared with k6 | dedicated vCPUs | dedicated vCPUs | dedicated vCPUs | dedicated vCPUs |
| Traefik node | control-plane node | `role=api` node | `role=api` node | `role=api` node | `role=api` node |

Kubernetes is v1.36 where offered, otherwise the nearest minor version
(recorded as a deviation). Region, instance types and the exact Kubernetes,
CNI and Calico versions are fixed when a cluster is created and recorded before
its first run. The NetworkPolicy engine is the one platform difference that
touches a control (c2, c6); it is reported with every c2 and c6 result.
metrics-server is installed in the version used on Kind where the platform has
none; where the platform runs its own, that one is used and its version
recorded.

Recorded before the EKS runs: the AWS account allows only region `eu-north-1`
and, on its free plan, only small instance types. The EKS nodes and the k6 VM
are therefore `m7i-flex.large` (2 vCPU, 8 GiB) instead of 4 vCPU and 16 GiB;
flex instances guarantee 40 % of each vCPU and may run at full speed most of
the time. Cluster: EKS 1.36 (nodes v1.36.5), both nodes and the k6 VM in zone
`eu-north-1a`; setup and teardown in `cloud/eks-up.sh` and `cloud/eks-down.sh`.

Before the runs on a platform: the EXP-05 verification on that cluster (all
checks pass). The scripts select the `cloud-*` overlays with `PLATFORM=cloud`;
Traefik is installed with `TRAEFIK_VALUES=cloud/traefik-values.yaml`. No change
to the k6 scripts or the application.

### 16.3 Design

Per platform, in the order GKE, EKS, OVH, AKS:

* **Part A**, as §11.2: all seven configurations, `/chat` (1 VU, 5 min measured,
  2 min warm-up) and `/health` (50 req/s, 2 min measured, 2 min warm-up),
  `MONITOR=0`, 3 repetitions in the rotated order of §11.2. Results:
  `results/exp-07-<platform>/`; tables: `scripts/overhead_table.py`.
* **Part B**, a short load check: `/health` at 50 and 100 req/s for c0, c5 and
  c6 with the EXP-02 settings (§9.1), 3 repetitions interleaved over the
  configurations, rule of §9.3 and per-run classes of §9.6. Throttling from
  Prometheus in the cluster (`scripts/throttle_table.py`). Results:
  `results/exp-07-<platform>-load/`. Kind references: §14.5 and §15.5.

`<platform>` is `gke`, `eks`, `ovh` or `aks`. A platform's cluster is deleted
after its runs. If the time does not allow all four platforms,
the platforms that were measured are named in the results, and the hypotheses
are evaluated for those only; a missing platform is not replaced by
estimates.

### 16.4 Hypotheses (stated before the runs)

H7.1 to H7.4 are evaluated on each platform separately.

* **H7.1 (`/health`, verdicts).** Every configuration gets the same verdict as
  in the Kind re-run: C1 and C2 within noise; C3, C4, C5 and C6 distinct, higher.
* **H7.2 (`/health`, ranking).** The single controls keep their order of added
  latency: mTLS < TLS < gateway, and C6 adds more than any single control.
* **H7.3 (`/chat`).** No configuration is distinct, higher than the baseline.
* **H7.4 (load).** No level of Part B is saturated for c0, c5 or c6, and the
  gateway (500 m limit) is throttled for at most 21.7 % of a 1-minute window at
  100 req/s, the highest value of the 500 m gateway at this level on Kind
  v1.36.4 (§14.5; §15.5: 14.1 %).
* **H7.5 (across platforms).** On every measured platform the `/health`
  overhead of C6 lies between half and twice the Kind value (+4.39 ms, §11.5),
  that is, between +2.2 and +8.8 ms.

### 16.5 How the result is read

The verdict rule of §6 applies unchanged. RQ2 is answered by comparing the
verdicts, the ranking and the added latency (Δ ms) of each control between Kind
and each platform, and between the platforms. A difference cannot be assigned
to one cause, because the platform, the network, the node CPUs, the CNI and the
load generator placement change together; for c2 and c6 the NetworkPolicy
engine is named with the result.

### 16.6 Results on EKS (21 Nov 2026)

EXP-05 on EKS: 40 of 40 checks pass, the same per configuration as on Kind
v1.36.4 (`results/exp-05-security-verification/eks/`). Part A: 42 runs, Part B:
18 runs, all valid (no pod restarts, no failed requests), 08:04 to 14:50 UTC,
one run at a time. Data: `results/exp-07-eks/` (table `overhead-summary.md`,
`scripts/overhead_table.py`) and `results/exp-07-eks-load/` (`load-summary.md`,
`throttling-summary.md`). On EKS, `host_cpu=` describes the k6 VM, not the
cluster nodes: it was 5.3 to 8.0 % busy in Part A and at most 8.7 % in Part B.
Deviations: as recorded in §16.2 (region `eu-north-1`, `m7i-flex.large` nodes
and k6 VM).

`/health` (Part A, Δ avg against c0, ms; Kind re-run §11.5 for comparison):

| Config | Δ ms EKS | Δ % EKS | Verdict EKS | Δ ms Kind |
| ------ | -------- | ------- | ----------- | --------- |
| c1-rbac | +0.01 | +0.4 | within noise | +0.04 |
| c2-netpol | +0.02 | +1.2 | within noise | -0.01 |
| c3-mtls | +0.41 | +26.2 | distinct, higher | +0.23 |
| c4-tls | +0.78 | +50.1 | distinct, higher | +0.73 |
| c5-gateway | +2.19 | +141.5 | distinct, higher | +2.20 |
| c6-all | +3.64 | +234.6 | distinct, higher | +4.39 |

c0 average: 1.55 ms on EKS, 1.99 ms on Kind. `/chat` c0 average: 1434.30 ms on
EKS, 1992.76 ms on Kind; every configuration within noise on both.

**H7.1.** Supported on EKS: C1 and C2 within noise, C3 to C6 distinct, higher.

**H7.2.** Supported on EKS: mTLS (+0.41) < TLS (+0.78) < gateway (+2.19), and
C6 (+3.64) adds more than any single control.

**H7.3.** Supported on EKS: no configuration is distinct, higher on `/chat`
(Δ between -4.66 and +2.00 ms).

**H7.4.** Supported on EKS: no level of Part B is saturated, and every run is
stable (no dropped request); the gateway was not throttled in any 1-minute
window (0.0 % at 50 and 100 req/s, against the threshold of 21.7 %).

**H7.5.** Holds for EKS: C6 adds +3.64 ms, within +2.2 to +8.8 ms. The
hypothesis is about all measured platforms and is decided when EXP-07 ends.

Part B, median overhead (runs without collapse, n = 3; Kind re-run §14.5 at
the same rates for comparison):

| Rate req/s | c0 median EKS | Δ c5 EKS | Δ c6 EKS | Δ c5 Kind | Δ c6 Kind |
| ---------- | ------------- | -------- | -------- | --------- | --------- |
| 50         | 1.53          | +2.19    | +3.84    | +2.64     | +3.97     |
| 100        | 1.36          | +1.85    | +3.05    | +2.62 (n = 2) | +4.35 |

Resources on `/health` at 50 req/s (request path): c5 +109 m and +41 Mi, c6
+189 m and +148 Mi against c0 on EKS; on Kind +122 m and +51 Mi, and +251 m and
+304 Mi (§11.5 table).

**Post-hoc: what differs from Kind.** Verdicts and ranking are the same; the
added latency of the gateway is almost identical (+2.19 against +2.20 ms).
mTLS costs more on EKS (+0.41 against +0.23 ms), all controls together less
(+3.64 against +4.39 ms). Absolute latencies are lower on EKS although the
nodes have 2 vCPU: on Kind the cluster and k6 share one host. Following §16.5
these differences are reported, not assigned to one cause.
