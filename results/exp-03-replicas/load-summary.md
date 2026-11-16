### /health latency per request rate

| Config | Target req/s | Achieved req/s | Avg ms | P95 ms | P99 ms | Failed % | Dropped | Runs | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 100.0 | 2.25 (1.96-2.82) | 3.47 | 4.87 | 0.00 | 0 | 3 | ok |
| c0-baseline | 150 | 150.0 | 3.68 (1.96-7.04) | 3.99 | 72.05 | 0.00 | 0 | 3 | ok |
| c0-baseline | 200 | 200.0 | 2.13 (1.99-2.31) | 3.26 | 11.42 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 100 | 100.0 | 4.62 (4.32-4.83) | 6.95 | 12.14 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 150 | 150.0 | 5.26 (4.75-5.54) | 8.26 | 30.37 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 200 | 199.9 | 20.29 (6.98-38.11) | 79.40 | 385.87 | 0.00 | 46 | 3 | saturated |
| c0-baseline-r2 | 100 | 100.0 | 2.38 (2.03-2.80) | 3.55 | 7.28 | 0.00 | 0 | 3 | ok |
| c0-baseline-r2 | 150 | 150.0 | 2.30 (2.01-2.87) | 3.57 | 6.94 | 0.00 | 0 | 3 | ok |
| c0-baseline-r2 | 200 | 200.0 | 2.37 (2.05-2.95) | 3.69 | 9.16 | 0.00 | 0 | 3 | ok |
| c0-baseline-r3 | 100 | 100.0 | 2.03 (1.97-2.12) | 2.96 | 4.37 | 0.00 | 0 | 3 | ok |
| c0-baseline-r3 | 150 | 150.0 | 1.99 (1.91-2.03) | 2.95 | 4.54 | 0.00 | 0 | 3 | ok |
| c0-baseline-r3 | 200 | 200.0 | 1.98 (1.89-2.04) | 2.99 | 5.00 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000-r2 | 100 | 99.9 | 6.92 (4.64-11.21) | 7.79 | 41.54 | 0.00 | 31 | 3 | saturated |
| c5-gateway-cpu1000-r2 | 150 | 150.0 | 5.03 (4.90-5.13) | 8.12 | 17.35 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000-r2 | 200 | 200.0 | 6.16 (5.70-6.99) | 11.43 | 41.43 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000-r3 | 100 | 100.0 | 4.83 (4.72-4.96) | 7.24 | 15.44 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000-r3 | 150 | 150.0 | 5.29 (5.01-5.64) | 8.14 | 24.87 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000-r3 | 200 | 200.0 | 7.31 (5.96-9.16) | 12.11 | 66.11 | 0.00 | 0 | 3 | ok |

### /health overhead against the baseline at each rate

| Rate req/s | Baseline avg ms | Δ c5-gateway-cpu1000 ms | Δ c0-baseline-r2 ms | Δ c0-baseline-r3 ms | Δ c5-gateway-cpu1000-r2 ms | Δ c5-gateway-cpu1000-r3 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 100 | 2.25 | +2.37 (distinct, higher) | +0.13 (within noise) | -0.22 (within noise) | n/a (saturated) | +2.58 (distinct, higher) |
| 150 | 3.68 | +1.57 (within noise) | -1.38 (within noise) | -1.70 (within noise) | +1.35 (within noise) | +1.61 (within noise) |
| 200 | 2.13 | n/a (saturated) | +0.24 (within noise) | -0.16 (within noise) | +4.02 (distinct, higher) | +5.18 (distinct, higher) |

### /health runs per level (post-hoc, methodology 9.6)

| Config | Rate req/s | Stable | Transient | Collapse | Median ms (runs without collapse) |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 3 | 0 | 0 | 1.79 |
| c0-baseline | 150 | 3 | 0 | 0 | 1.71 |
| c0-baseline | 200 | 3 | 0 | 0 | 1.64 |
| c5-gateway-cpu1000 | 100 | 3 | 0 | 0 | 4.11 |
| c5-gateway-cpu1000 | 150 | 3 | 0 | 0 | 4.12 |
| c5-gateway-cpu1000 | 200 | 2 | 1 | 0 | 4.36 |
| c0-baseline-r2 | 100 | 3 | 0 | 0 | 2.04 |
| c0-baseline-r2 | 150 | 3 | 0 | 0 | 1.81 |
| c0-baseline-r2 | 200 | 3 | 0 | 0 | 1.76 |
| c0-baseline-r3 | 100 | 3 | 0 | 0 | 1.82 |
| c0-baseline-r3 | 150 | 3 | 0 | 0 | 1.81 |
| c0-baseline-r3 | 200 | 3 | 0 | 0 | 1.77 |
| c5-gateway-cpu1000-r2 | 100 | 2 | 1 | 0 | 4.19 |
| c5-gateway-cpu1000-r2 | 150 | 3 | 0 | 0 | 4.28 |
| c5-gateway-cpu1000-r2 | 200 | 3 | 0 | 0 | 4.38 |
| c5-gateway-cpu1000-r3 | 100 | 3 | 0 | 0 | 4.18 |
| c5-gateway-cpu1000-r3 | 150 | 3 | 0 | 0 | 4.26 |
| c5-gateway-cpu1000-r3 | 200 | 3 | 0 | 0 | 4.48 |

### /health overhead from medians, runs without collapse (post-hoc)

A cell needs at least 2 such runs for the configuration and the baseline.

| Rate req/s | Baseline median ms | Δ c5-gateway-cpu1000 ms | Δ c0-baseline-r2 ms | Δ c0-baseline-r3 ms | Δ c5-gateway-cpu1000-r2 ms | Δ c5-gateway-cpu1000-r3 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 100 | 1.79 | +2.32 (n=3) | +0.25 (n=3) | +0.03 (n=3) | +2.40 (n=3) | +2.39 (n=3) |
| 150 | 1.71 | +2.41 (n=3) | +0.10 (n=3) | +0.10 (n=3) | +2.57 (n=3) | +2.55 (n=3) |
| 200 | 1.64 | +2.71 (n=3) | +0.12 (n=3) | +0.13 (n=3) | +2.74 (n=3) | +2.83 (n=3) |

### CPU per pod on the /health path (millicores, mean of run means)

CPU limits in the manifests: fastapi 1000 m, gateway 500 m (1000 m in the c5-gateway-cpu1000 configurations), traefik none. A pod at its limit is throttled by the kernel.
With more than one replica the value is the sum over all replicas.
Pods that are not on the request path of a configuration show '-'.

| Config | Rate req/s | fastapi m | gateway m | traefik m |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 202 | - | - |
| c0-baseline | 150 | 286 | - | - |
| c0-baseline | 200 | 327 | - | - |
| c5-gateway-cpu1000 | 100 | 156 | 282 | - |
| c5-gateway-cpu1000 | 150 | 228 | 427 | - |
| c5-gateway-cpu1000 | 200 | 303 | 618 | - |
| c0-baseline-r2 | 100 | 202 | - | - |
| c0-baseline-r2 | 150 | 298 | - | - |
| c0-baseline-r2 | 200 | 396 | - | - |
| c0-baseline-r3 | 100 | 186 | - | - |
| c0-baseline-r3 | 150 | 265 | - | - |
| c0-baseline-r3 | 200 | 345 | - | - |
| c5-gateway-cpu1000-r2 | 100 | 162 | 302 | - |
| c5-gateway-cpu1000-r2 | 150 | 239 | 460 | - |
| c5-gateway-cpu1000-r2 | 200 | 339 | 647 | - |
| c5-gateway-cpu1000-r3 | 100 | 165 | 296 | - |
| c5-gateway-cpu1000-r3 | 150 | 251 | 465 | - |
| c5-gateway-cpu1000-r3 | 200 | 364 | 677 | - |

### Memory per pod on the /health path (Mi, mean of run means)

With more than one replica the value is the sum over all replicas.

| Config | Rate req/s | fastapi Mi | gateway Mi | traefik Mi |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 53 | - | - |
| c0-baseline | 150 | 54 | - | - |
| c0-baseline | 200 | 55 | - | - |
| c5-gateway-cpu1000 | 100 | 46 | 48 | - |
| c5-gateway-cpu1000 | 150 | 46 | 48 | - |
| c5-gateway-cpu1000 | 200 | 48 | 49 | - |
| c0-baseline-r2 | 100 | 100 | - | - |
| c0-baseline-r2 | 150 | 101 | - | - |
| c0-baseline-r2 | 200 | 101 | - | - |
| c0-baseline-r3 | 100 | 142 | - | - |
| c0-baseline-r3 | 150 | 143 | - | - |
| c0-baseline-r3 | 200 | 144 | - | - |
| c5-gateway-cpu1000-r2 | 100 | 98 | 93 | - |
| c5-gateway-cpu1000-r2 | 150 | 98 | 93 | - |
| c5-gateway-cpu1000-r2 | 200 | 98 | 94 | - |
| c5-gateway-cpu1000-r3 | 100 | 148 | 139 | - |
| c5-gateway-cpu1000-r3 | 150 | 148 | 139 | - |
| c5-gateway-cpu1000-r3 | 200 | 149 | 141 | - |

