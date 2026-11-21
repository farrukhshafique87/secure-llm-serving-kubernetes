### /health latency per request rate

| Config | Target req/s | Achieved req/s | Avg ms | P95 ms | P99 ms | Failed % | Dropped | Runs | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 50.0 | 1.61 (1.58-1.65) | 1.98 | 2.92 | 0.00 | 0 | 3 | ok |
| c0-baseline | 100 | 100.0 | 1.40 (1.36-1.43) | 1.77 | 2.57 | 0.00 | 0 | 3 | ok |
| c5-gateway | 50 | 50.0 | 3.87 (3.82-3.92) | 4.83 | 7.44 | 0.00 | 0 | 3 | ok |
| c5-gateway | 100 | 100.0 | 3.35 (3.29-3.41) | 4.26 | 6.62 | 0.00 | 0 | 3 | ok |
| c6-all | 50 | 50.0 | 5.57 (5.52-5.63) | 7.07 | 10.59 | 0.00 | 0 | 3 | ok |
| c6-all | 100 | 100.0 | 4.70 (4.63-4.83) | 6.28 | 10.00 | 0.00 | 0 | 3 | ok |

### /health overhead against the baseline at each rate

| Rate req/s | Baseline avg ms | Δ c5-gateway ms | Δ c6-all ms |
| --- | --- | --- | --- |
| 50 | 1.61 | +2.26 (distinct, higher) | +3.96 (distinct, higher) |
| 100 | 1.40 | +1.95 (distinct, higher) | +3.30 (distinct, higher) |

### /health runs per level (post-hoc, methodology 9.6)

| Config | Rate req/s | Stable | Transient | Collapse | Median ms (runs without collapse) |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 0 | 0 | 1.53 |
| c0-baseline | 100 | 3 | 0 | 0 | 1.36 |
| c5-gateway | 50 | 3 | 0 | 0 | 3.72 |
| c5-gateway | 100 | 3 | 0 | 0 | 3.21 |
| c6-all | 50 | 3 | 0 | 0 | 5.37 |
| c6-all | 100 | 3 | 0 | 0 | 4.41 |

### /health overhead from medians, runs without collapse (post-hoc)

A cell needs at least 2 such runs for the configuration and the baseline.

| Rate req/s | Baseline median ms | Δ c5-gateway ms | Δ c6-all ms |
| --- | --- | --- | --- |
| 50 | 1.53 | +2.19 (n=3) | +3.84 (n=3) |
| 100 | 1.36 | +1.85 (n=3) | +3.05 (n=3) |

### CPU per pod on the /health path (millicores, mean of run means)

CPU limits in the manifests: fastapi 1000 m, gateway 500 m (1000 m in the c5-gateway-cpu1000 configurations), traefik none. A pod at its limit is throttled by the kernel.
With more than one replica the value is the sum over all replicas.
Pods that are not on the request path of a configuration show '-'.

| Config | Rate req/s | fastapi m | gateway m | traefik m |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 70 | - | - |
| c0-baseline | 100 | 117 | - | - |
| c5-gateway | 50 | 67 | 115 | - |
| c5-gateway | 100 | 119 | 198 | - |
| c6-all | 50 | 83 | 145 | 34 |
| c6-all | 100 | 151 | 245 | 50 |

### Memory per pod on the /health path (Mi, mean of run means)

With more than one replica the value is the sum over all replicas.

| Config | Rate req/s | fastapi Mi | gateway Mi | traefik Mi |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 43 | - | - |
| c0-baseline | 100 | 43 | - | - |
| c5-gateway | 50 | 42 | 41 | - |
| c5-gateway | 100 | 43 | 41 | - |
| c6-all | 50 | 46 | 44 | 32 |
| c6-all | 100 | 46 | 44 | 35 |

