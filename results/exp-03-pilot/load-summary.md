### /health latency per request rate

| Config | Target req/s | Achieved req/s | Avg ms | P95 ms | P99 ms | Failed % | Dropped | Runs | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 100.0 | 2.03 (2.03-2.03) | 2.99 | 4.24 | 0.00 | 0 | 1 | ok |
| c0-baseline | 150 | 150.0 | 2.07 (2.07-2.07) | 3.16 | 6.70 | 0.00 | 0 | 1 | ok |
| c0-baseline | 200 | 200.0 | 2.64 (2.64-2.64) | 3.38 | 12.11 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000 | 100 | 100.0 | 6.24 (6.24-6.24) | 9.51 | 21.34 | 0.01 | 0 | 1 | ok |
| c5-gateway-cpu1000 | 150 | 150.0 | 9.10 (9.10-9.10) | 18.58 | 119.07 | 0.01 | 0 | 1 | ok |
| c5-gateway-cpu1000 | 200 | 182.4 | 253.70 (253.70-253.70) | 2432.36 | 3763.64 | 0.00 | 1894 | 1 | saturated |
| c0-baseline-r2 | 100 | 100.0 | 1.96 (1.96-1.96) | 2.85 | 4.18 | 0.00 | 0 | 1 | ok |
| c0-baseline-r2 | 150 | 150.0 | 2.10 (2.10-2.10) | 3.28 | 5.94 | 0.00 | 0 | 1 | ok |
| c0-baseline-r2 | 200 | 200.0 | 3.05 (3.05-3.05) | 4.70 | 28.68 | 0.00 | 0 | 1 | ok |
| c0-baseline-r3 | 100 | 100.0 | 1.90 (1.90-1.90) | 2.71 | 3.57 | 0.00 | 0 | 1 | ok |
| c0-baseline-r3 | 150 | 150.0 | 1.96 (1.96-1.96) | 3.03 | 4.36 | 0.00 | 0 | 1 | ok |
| c0-baseline-r3 | 200 | 200.0 | 1.92 (1.92-1.92) | 2.96 | 4.66 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r2 | 100 | 100.0 | 5.62 (5.62-5.62) | 8.86 | 12.61 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r2 | 150 | 150.0 | 5.63 (5.63-5.63) | 9.05 | 16.54 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r2 | 200 | 200.0 | 6.26 (6.26-6.26) | 11.24 | 22.66 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r3 | 100 | 100.0 | 5.80 (5.80-5.80) | 9.10 | 11.55 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r3 | 150 | 150.0 | 5.49 (5.49-5.49) | 8.42 | 12.55 | 0.00 | 0 | 1 | ok |
| c5-gateway-cpu1000-r3 | 200 | 200.0 | 7.15 (7.15-7.15) | 11.29 | 27.47 | 0.00 | 0 | 1 | ok |

### /health overhead against the baseline at each rate

| Rate req/s | Baseline avg ms | Δ c5-gateway-cpu1000 ms | Δ c0-baseline-r2 ms | Δ c0-baseline-r3 ms | Δ c5-gateway-cpu1000-r2 ms | Δ c5-gateway-cpu1000-r3 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 100 | 2.03 | +4.20 (distinct, higher) | -0.07 (distinct, lower) | -0.13 (distinct, lower) | +3.59 (distinct, higher) | +3.77 (distinct, higher) |
| 150 | 2.07 | +7.04 (distinct, higher) | +0.03 (distinct, higher) | -0.10 (distinct, lower) | +3.56 (distinct, higher) | +3.42 (distinct, higher) |
| 200 | 2.64 | n/a (saturated) | +0.41 (distinct, higher) | -0.73 (distinct, lower) | +3.61 (distinct, higher) | +4.51 (distinct, higher) |

### /health runs per level (post-hoc, methodology 9.6)

| Config | Rate req/s | Stable | Transient | Collapse | Median ms (runs without collapse) |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 1 | 0 | 0 | 1.86 |
| c0-baseline | 150 | 1 | 0 | 0 | 1.79 |
| c0-baseline | 200 | 1 | 0 | 0 | 1.77 |
| c5-gateway-cpu1000 | 100 | 1 | 0 | 0 | 5.14 |
| c5-gateway-cpu1000 | 150 | 1 | 0 | 0 | 4.92 |
| c5-gateway-cpu1000 | 200 | 0 | 0 | 1 | - |
| c0-baseline-r2 | 100 | 1 | 0 | 0 | 1.80 |
| c0-baseline-r2 | 150 | 1 | 0 | 0 | 1.81 |
| c0-baseline-r2 | 200 | 1 | 0 | 0 | 1.92 |
| c0-baseline-r3 | 100 | 1 | 0 | 0 | 1.78 |
| c0-baseline-r3 | 150 | 1 | 0 | 0 | 1.77 |
| c0-baseline-r3 | 200 | 1 | 0 | 0 | 1.72 |
| c5-gateway-cpu1000-r2 | 100 | 1 | 0 | 0 | 5.03 |
| c5-gateway-cpu1000-r2 | 150 | 1 | 0 | 0 | 4.93 |
| c5-gateway-cpu1000-r2 | 200 | 1 | 0 | 0 | 5.20 |
| c5-gateway-cpu1000-r3 | 100 | 1 | 0 | 0 | 5.28 |
| c5-gateway-cpu1000-r3 | 150 | 1 | 0 | 0 | 4.99 |
| c5-gateway-cpu1000-r3 | 200 | 1 | 0 | 0 | 5.38 |

### /health overhead from medians, runs without collapse (post-hoc)

A cell needs at least 2 such runs for the configuration and the baseline.

| Rate req/s | Baseline median ms | Δ c5-gateway-cpu1000 ms | Δ c0-baseline-r2 ms | Δ c0-baseline-r3 ms | Δ c5-gateway-cpu1000-r2 ms | Δ c5-gateway-cpu1000-r3 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 100 | 1.86 | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) |
| 150 | 1.79 | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) |
| 200 | 1.77 | n/a (1 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) | n/a (0 of 1 collapsed) |

### CPU per pod on the /health path (millicores, mean of run means)

CPU limits in the manifests: fastapi 1000 m, gateway 500 m (1000 m in the c5-gateway-cpu1000 configurations), traefik none. A pod at its limit is throttled by the kernel.
With more than one replica the value is the sum over all replicas.
Pods that are not on the request path of a configuration show '-'.

| Config | Rate req/s | fastapi m | gateway m | traefik m |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 178 | - | - |
| c0-baseline | 150 | 240 | - | - |
| c0-baseline | 200 | 342 | - | - |
| c5-gateway-cpu1000 | 100 | 197 | 371 | - |
| c5-gateway-cpu1000 | 150 | 280 | 500 | - |
| c5-gateway-cpu1000 | 200 | 354 | 706 | - |
| c0-baseline-r2 | 100 | 175 | - | - |
| c0-baseline-r2 | 150 | 258 | - | - |
| c0-baseline-r2 | 200 | 414 | - | - |
| c0-baseline-r3 | 100 | 172 | - | - |
| c0-baseline-r3 | 150 | 266 | - | - |
| c0-baseline-r3 | 200 | 340 | - | - |
| c5-gateway-cpu1000-r2 | 100 | 204 | 362 | - |
| c5-gateway-cpu1000-r2 | 150 | 277 | 487 | - |
| c5-gateway-cpu1000-r2 | 200 | 370 | 722 | - |
| c5-gateway-cpu1000-r3 | 100 | 206 | 376 | - |
| c5-gateway-cpu1000-r3 | 150 | 292 | 524 | - |
| c5-gateway-cpu1000-r3 | 200 | 393 | 722 | - |

### Memory per pod on the /health path (Mi, mean of run means)

With more than one replica the value is the sum over all replicas.

| Config | Rate req/s | fastapi Mi | gateway Mi | traefik Mi |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 53 | - | - |
| c0-baseline | 150 | 55 | - | - |
| c0-baseline | 200 | 55 | - | - |
| c5-gateway-cpu1000 | 100 | 42 | 43 | - |
| c5-gateway-cpu1000 | 150 | 43 | 44 | - |
| c5-gateway-cpu1000 | 200 | 43 | 44 | - |
| c0-baseline-r2 | 100 | 106 | - | - |
| c0-baseline-r2 | 150 | 106 | - | - |
| c0-baseline-r2 | 200 | 106 | - | - |
| c0-baseline-r3 | 100 | 150 | - | - |
| c0-baseline-r3 | 150 | 150 | - | - |
| c0-baseline-r3 | 200 | 151 | - | - |
| c5-gateway-cpu1000-r2 | 100 | 89 | 98 | - |
| c5-gateway-cpu1000-r2 | 150 | 90 | 99 | - |
| c5-gateway-cpu1000-r2 | 200 | 89 | 100 | - |
| c5-gateway-cpu1000-r3 | 100 | 131 | 140 | - |
| c5-gateway-cpu1000-r3 | 150 | 131 | 140 | - |
| c5-gateway-cpu1000-r3 | 200 | 132 | 141 | - |

