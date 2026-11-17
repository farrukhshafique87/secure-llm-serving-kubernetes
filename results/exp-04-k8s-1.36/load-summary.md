### /health latency per request rate

| Config | Target req/s | Achieved req/s | Avg ms | P95 ms | P99 ms | Failed % | Dropped | Runs | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 50.0 | 1.99 (1.90-2.08) | 2.65 | 3.41 | 0.00 | 0 | 3 | ok |
| c0-baseline | 60 | 60.0 | 1.94 (1.92-1.97) | 2.53 | 3.31 | 0.00 | 0 | 3 | ok |
| c0-baseline | 70 | 70.0 | 1.90 (1.88-1.92) | 2.50 | 3.31 | 0.00 | 0 | 3 | ok |
| c0-baseline | 80 | 80.0 | 1.99 (1.87-2.21) | 2.50 | 3.44 | 0.00 | 0 | 3 | ok |
| c0-baseline | 90 | 90.0 | 2.09 (1.83-2.61) | 3.06 | 4.02 | 0.00 | 0 | 3 | ok |
| c0-baseline | 100 | 100.0 | 2.08 (1.81-2.61) | 3.04 | 4.13 | 0.00 | 0 | 3 | ok |
| c0-baseline | 120 | 120.0 | 2.07 (1.78-2.65) | 3.07 | 4.17 | 0.00 | 0 | 3 | ok |
| c0-baseline | 150 | 150.0 | 1.95 (1.71-2.42) | 2.90 | 4.16 | 0.00 | 0 | 3 | ok |
| c5-gateway | 50 | 50.0 | 4.58 (4.10-5.37) | 6.58 | 8.88 | 0.00 | 0 | 3 | ok |
| c5-gateway | 60 | 60.0 | 4.47 (4.07-5.19) | 6.28 | 8.15 | 0.00 | 0 | 3 | ok |
| c5-gateway | 70 | 70.0 | 4.49 (4.06-5.36) | 6.40 | 8.59 | 0.00 | 0 | 3 | ok |
| c5-gateway | 80 | 80.0 | 4.54 (4.04-5.47) | 6.47 | 8.83 | 0.00 | 0 | 3 | ok |
| c5-gateway | 90 | 90.0 | 4.78 (4.11-5.84) | 6.90 | 14.51 | 0.00 | 0 | 3 | ok |
| c5-gateway | 100 | 100.0 | 5.88 (4.18-8.71) | 10.21 | 43.69 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 50 | 50.0 | 4.15 (4.10-4.22) | 5.51 | 7.09 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 60 | 60.0 | 4.14 (4.13-4.16) | 5.46 | 7.23 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 70 | 70.0 | 4.12 (4.06-4.19) | 5.55 | 7.50 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 80 | 80.0 | 4.18 (4.08-4.23) | 5.80 | 7.90 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 90 | 90.0 | 4.32 (4.11-4.65) | 5.97 | 9.26 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 100 | 100.0 | 4.21 (4.09-4.38) | 6.03 | 9.11 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 120 | 120.0 | 4.46 (4.15-4.97) | 6.14 | 14.22 | 0.00 | 0 | 3 | ok |
| c5-gateway-cpu1000 | 150 | 150.0 | 6.40 (4.51-9.67) | 11.49 | 67.21 | 0.00 | 0 | 3 | ok |

### /health overhead against the baseline at each rate

| Rate req/s | Baseline avg ms | Δ c5-gateway ms | Δ c5-gateway-cpu1000 ms |
| --- | --- | --- | --- |
| 50 | 1.99 | +2.59 (distinct, higher) | +2.15 (distinct, higher) |
| 60 | 1.94 | +2.53 (distinct, higher) | +2.20 (distinct, higher) |
| 70 | 1.90 | +2.60 (distinct, higher) | +2.23 (distinct, higher) |
| 80 | 1.99 | +2.55 (distinct, higher) | +2.19 (distinct, higher) |
| 90 | 2.09 | +2.69 (distinct, higher) | +2.23 (distinct, higher) |
| 100 | 2.08 | +3.80 (distinct, higher) | +2.14 (distinct, higher) |
| 120 | 2.07 | - | +2.39 (distinct, higher) |
| 150 | 1.95 | - | +4.45 (distinct, higher) |

### /health runs per level (post-hoc, methodology 9.6)

| Config | Rate req/s | Stable | Transient | Collapse | Median ms (runs without collapse) |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 0 | 0 | 1.92 |
| c0-baseline | 60 | 3 | 0 | 0 | 1.84 |
| c0-baseline | 70 | 3 | 0 | 0 | 1.79 |
| c0-baseline | 80 | 3 | 0 | 0 | 1.79 |
| c0-baseline | 90 | 3 | 0 | 0 | 1.74 |
| c0-baseline | 100 | 3 | 0 | 0 | 1.71 |
| c0-baseline | 120 | 3 | 0 | 0 | 1.67 |
| c0-baseline | 150 | 3 | 0 | 0 | 1.57 |
| c5-gateway | 50 | 3 | 0 | 0 | 3.95 |
| c5-gateway | 60 | 3 | 0 | 0 | 3.96 |
| c5-gateway | 70 | 3 | 0 | 0 | 3.86 |
| c5-gateway | 80 | 3 | 0 | 0 | 3.84 |
| c5-gateway | 90 | 3 | 0 | 0 | 3.91 |
| c5-gateway | 100 | 3 | 0 | 0 | 3.95 |
| c5-gateway-cpu1000 | 50 | 3 | 0 | 0 | 3.92 |
| c5-gateway-cpu1000 | 60 | 3 | 0 | 0 | 3.93 |
| c5-gateway-cpu1000 | 70 | 3 | 0 | 0 | 3.88 |
| c5-gateway-cpu1000 | 80 | 3 | 0 | 0 | 3.89 |
| c5-gateway-cpu1000 | 90 | 3 | 0 | 0 | 3.87 |
| c5-gateway-cpu1000 | 100 | 3 | 0 | 0 | 3.86 |
| c5-gateway-cpu1000 | 120 | 3 | 0 | 0 | 3.84 |
| c5-gateway-cpu1000 | 150 | 3 | 0 | 0 | 3.90 |

### /health overhead from medians, runs without collapse (post-hoc)

A cell needs at least 2 such runs for the configuration and the baseline.

| Rate req/s | Baseline median ms | Δ c5-gateway ms | Δ c5-gateway-cpu1000 ms |
| --- | --- | --- | --- |
| 50 | 1.92 | +2.03 (n=3) | +2.00 (n=3) |
| 60 | 1.84 | +2.12 (n=3) | +2.08 (n=3) |
| 70 | 1.79 | +2.06 (n=3) | +2.08 (n=3) |
| 80 | 1.79 | +2.06 (n=3) | +2.11 (n=3) |
| 90 | 1.74 | +2.16 (n=3) | +2.12 (n=3) |
| 100 | 1.71 | +2.24 (n=3) | +2.15 (n=3) |
| 120 | 1.67 | - | +2.17 (n=3) |
| 150 | 1.57 | - | +2.33 (n=3) |

### CPU per pod on the /health path (millicores, mean of run means)

CPU limits in the manifests: fastapi 1000 m, gateway 500 m (1000 m in the c5-gateway-cpu1000 configurations), traefik none. A pod at its limit is throttled by the kernel.
With more than one replica the value is the sum over all replicas.
Pods that are not on the request path of a configuration show '-'.

| Config | Rate req/s | fastapi m | gateway m | traefik m |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 88 | - | - |
| c0-baseline | 60 | 103 | - | - |
| c0-baseline | 70 | 117 | - | - |
| c0-baseline | 80 | 125 | - | - |
| c0-baseline | 90 | 164 | - | - |
| c0-baseline | 100 | 178 | - | - |
| c0-baseline | 120 | 212 | - | - |
| c0-baseline | 150 | 241 | - | - |
| c5-gateway | 50 | 81 | 147 | - |
| c5-gateway | 60 | 93 | 170 | - |
| c5-gateway | 70 | 108 | 195 | - |
| c5-gateway | 80 | 125 | 223 | - |
| c5-gateway | 90 | 141 | 262 | - |
| c5-gateway | 100 | 158 | 291 | - |
| c5-gateway-cpu1000 | 50 | 70 | 136 | - |
| c5-gateway-cpu1000 | 60 | 86 | 160 | - |
| c5-gateway-cpu1000 | 70 | 97 | 180 | - |
| c5-gateway-cpu1000 | 80 | 117 | 216 | - |
| c5-gateway-cpu1000 | 90 | 130 | 242 | - |
| c5-gateway-cpu1000 | 100 | 143 | 263 | - |
| c5-gateway-cpu1000 | 120 | 173 | 314 | - |
| c5-gateway-cpu1000 | 150 | 216 | 405 | - |

### Memory per pod on the /health path (Mi, mean of run means)

With more than one replica the value is the sum over all replicas.

| Config | Rate req/s | fastapi Mi | gateway Mi | traefik Mi |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 51 | - | - |
| c0-baseline | 60 | 51 | - | - |
| c0-baseline | 70 | 51 | - | - |
| c0-baseline | 80 | 52 | - | - |
| c0-baseline | 90 | 52 | - | - |
| c0-baseline | 100 | 52 | - | - |
| c0-baseline | 120 | 53 | - | - |
| c0-baseline | 150 | 53 | - | - |
| c5-gateway | 50 | 47 | 47 | - |
| c5-gateway | 60 | 48 | 47 | - |
| c5-gateway | 70 | 48 | 47 | - |
| c5-gateway | 80 | 48 | 48 | - |
| c5-gateway | 90 | 48 | 48 | - |
| c5-gateway | 100 | 48 | 48 | - |
| c5-gateway-cpu1000 | 50 | 47 | 46 | - |
| c5-gateway-cpu1000 | 60 | 47 | 46 | - |
| c5-gateway-cpu1000 | 70 | 47 | 46 | - |
| c5-gateway-cpu1000 | 80 | 48 | 46 | - |
| c5-gateway-cpu1000 | 90 | 48 | 46 | - |
| c5-gateway-cpu1000 | 100 | 48 | 46 | - |
| c5-gateway-cpu1000 | 120 | 48 | 46 | - |
| c5-gateway-cpu1000 | 150 | 48 | 47 | - |

