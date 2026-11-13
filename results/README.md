# Experiment results

Raw output of every experiment run, kept unchanged as evidence.
The overhead tables come from [`exp-06-final/overhead-summary.md`](exp-06-final/overhead-summary.md).

## Folders

| Folder | Contents | Status |
| --- | --- | --- |
| `exp-01-baseline` | EXP-01: baseline (c0), 3 runs on `/chat` and 3 on `/health`; `summary.md` from `scripts/summarize_results.py` (includes tokens/s) | Final |
| `exp-02-load` | EXP-02: `/health` on c0, c5, c6 at 50-100 req/s (c0 also 150, 200) and `/chat` on c0, c6 at 1, 2, 4 VUs, 3 repetitions, `MONITOR=1` | Final |
| `exp-02-pilot` | EXP-02 pilot: `/health` on c0, c5 and c6 at 50 to 200 req/s, 1 run each, to choose the sweep levels | Pilot, not used for conclusions |
| `exp-04-gateway-cpu` | EXP-04: `/health` on c0, c5 (gateway 500 m) and c5-gateway-cpu1000 at 50-100 req/s (c0 and 1000 m also 120, 150), 3 repetitions, `MONITOR=1`, with CPU throttling per run | Final |
| `exp-04-pilot` | EXP-04 pilot: c5 at 500 m and 1000 m, 70 and 100 req/s, 1 run each, to check the setup | Pilot, not used for conclusions |
| `exp-05-security-verification` | EXP-05: evidence that each control works (RBAC, NetworkPolicy, mTLS, all controls); `k8s-1.36/`: re-run on Kubernetes v1.36.4 with live TLS and gateway checks, all 7 configurations | Final |
| `exp-06-final` | EXP-06: 7 configurations x 3 repetitions, interleaved. Source of the overhead tables | Final |

## Files per run

| File | Contents |
| --- | --- |
| `<config>-r<N>.json` | k6 summary for `/chat` (checks, latency, request rate) |
| `<config>-health-r<N>.json` | k6 summary for `/health` |
| `*.meta.txt` | Run ID, start and end time, k6 script, VUs, duration, validity (no pod restarts) |
| `*.resources.txt` | CPU (millicores) and memory per pod, sampled during the run |
| `*-environment.txt` | Host, CPU cores, memory and tool versions at run time |
| `throttling.csv`, `throttling-summary.md` | CPU throttling per run and container, read from Prometheus (`scripts/throttle_table.py`); EXP-02 and EXP-04 |

## Environment (exp-06-final)

Windows 11 + WSL2, 8 CPU cores, 10 GiB memory for WSL, Docker 29.6.2, Kind cluster.
Exact details are recorded in each `*-environment.txt`.
