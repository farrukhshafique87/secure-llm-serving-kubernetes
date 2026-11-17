### /health latency per request rate

| Config | Target req/s | Achieved req/s | Avg ms | P95 ms | P99 ms | Failed % | Dropped | Runs | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 50.0 | 2.30 (1.93-2.99) | 3.39 | 9.11 | 0.00 | 0 | 3 | ok |
| c0-baseline | 60 | 60.0 | 1.95 (1.93-2.00) | 2.57 | 3.38 | 0.00 | 0 | 3 | ok |
| c0-baseline | 70 | 70.0 | 1.89 (1.88-1.89) | 2.48 | 3.23 | 0.00 | 0 | 3 | ok |
| c0-baseline | 80 | 80.0 | 1.88 (1.87-1.89) | 2.49 | 3.33 | 0.00 | 0 | 3 | ok |
| c0-baseline | 90 | 90.0 | 1.87 (1.84-1.93) | 2.61 | 3.39 | 0.00 | 0 | 3 | ok |
| c0-baseline | 100 | 100.0 | 1.81 (1.80-1.81) | 2.41 | 3.26 | 0.00 | 0 | 3 | ok |
| c0-baseline | 150 | 150.0 | 1.84 (1.71-1.91) | 2.62 | 4.44 | 0.00 | 0 | 3 | ok |
| c0-baseline | 200 | 200.0 | 1.70 (1.69-1.71) | 2.56 | 3.94 | 0.00 | 0 | 3 | ok |
| c5-gateway | 50 | 50.0 | 6.11 (4.15-9.29) | 6.99 | 48.91 | 0.00 | 0 | 3 | ok |
| c5-gateway | 60 | 60.0 | 4.77 (4.09-5.15) | 7.06 | 9.23 | 0.00 | 0 | 3 | ok |
| c5-gateway | 70 | 70.0 | 4.87 (4.20-5.24) | 7.37 | 9.67 | 0.00 | 0 | 3 | ok |
| c5-gateway | 80 | 80.0 | 4.88 (4.11-5.35) | 7.39 | 9.52 | 0.00 | 0 | 3 | ok |
| c5-gateway | 90 | 90.0 | 5.35 (4.97-5.58) | 7.68 | 15.41 | 0.00 | 0 | 3 | ok |
| c5-gateway | 100 | 98.7 | 44.38 (4.20-123.22) | 189.53 | 859.96 | 0.00 | 356 | 3 | saturated |
| c6-all | 50 | 50.0 | 6.67 (6.15-7.72) | 9.14 | 11.96 | 0.00 | 0 | 3 | ok |
| c6-all | 60 | 60.0 | 7.27 (6.33-7.91) | 10.62 | 19.36 | 0.00 | 0 | 3 | ok |
| c6-all | 70 | 70.0 | 6.70 (6.25-7.57) | 9.14 | 11.77 | 0.00 | 0 | 3 | ok |
| c6-all | 80 | 80.0 | 7.44 (7.03-7.81) | 10.13 | 20.57 | 0.00 | 0 | 3 | ok |
| c6-all | 90 | 89.8 | 36.56 (6.44-95.63) | 217.85 | 604.96 | 0.00 | 62 | 3 | saturated |
| c6-all | 100 | 100.0 | 7.10 (6.56-8.05) | 9.99 | 18.77 | 0.00 | 0 | 3 | ok |

### /health overhead against the baseline at each rate

| Rate req/s | Baseline avg ms | Δ c5-gateway ms | Δ c6-all ms |
| --- | --- | --- | --- |
| 50 | 2.30 | +3.81 (distinct, higher) | +4.37 (distinct, higher) |
| 60 | 1.95 | +2.81 (distinct, higher) | +5.32 (distinct, higher) |
| 70 | 1.89 | +2.98 (distinct, higher) | +4.81 (distinct, higher) |
| 80 | 1.88 | +3.00 (distinct, higher) | +5.56 (distinct, higher) |
| 90 | 1.87 | +3.48 (distinct, higher) | n/a (saturated) |
| 100 | 1.81 | n/a (saturated) | +5.29 (distinct, higher) |
| 150 | 1.84 | - | - |
| 200 | 1.70 | - | - |

### /health runs per level (post-hoc, methodology 9.6)

| Config | Rate req/s | Stable | Transient | Collapse | Median ms (runs without collapse) |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 0 | 0 | 1.89 |
| c0-baseline | 60 | 3 | 0 | 0 | 1.85 |
| c0-baseline | 70 | 3 | 0 | 0 | 1.80 |
| c0-baseline | 80 | 3 | 0 | 0 | 1.78 |
| c0-baseline | 90 | 3 | 0 | 0 | 1.75 |
| c0-baseline | 100 | 3 | 0 | 0 | 1.71 |
| c0-baseline | 150 | 3 | 0 | 0 | 1.60 |
| c0-baseline | 200 | 3 | 0 | 0 | 1.51 |
| c5-gateway | 50 | 3 | 0 | 0 | 4.53 |
| c5-gateway | 60 | 3 | 0 | 0 | 4.62 |
| c5-gateway | 70 | 3 | 0 | 0 | 4.76 |
| c5-gateway | 80 | 3 | 0 | 0 | 4.77 |
| c5-gateway | 90 | 3 | 0 | 0 | 4.85 |
| c5-gateway | 100 | 2 | 0 | 1 | 4.32 |
| c6-all | 50 | 3 | 0 | 0 | 5.86 |
| c6-all | 60 | 3 | 0 | 0 | 6.52 |
| c6-all | 70 | 3 | 0 | 0 | 5.95 |
| c6-all | 80 | 3 | 0 | 0 | 6.65 |
| c6-all | 90 | 2 | 1 | 0 | 6.83 |
| c6-all | 100 | 3 | 0 | 0 | 6.05 |

### /health overhead from medians, runs without collapse (post-hoc)

A cell needs at least 2 such runs for the configuration and the baseline.

| Rate req/s | Baseline median ms | Δ c5-gateway ms | Δ c6-all ms |
| --- | --- | --- | --- |
| 50 | 1.89 | +2.64 (n=3) | +3.97 (n=3) |
| 60 | 1.85 | +2.77 (n=3) | +4.67 (n=3) |
| 70 | 1.80 | +2.96 (n=3) | +4.15 (n=3) |
| 80 | 1.78 | +2.99 (n=3) | +4.88 (n=3) |
| 90 | 1.75 | +3.10 (n=3) | +5.08 (n=3) |
| 100 | 1.71 | +2.62 (n=2) | +4.35 (n=3) |
| 150 | 1.60 | - | - |
| 200 | 1.51 | - | - |

### CPU per pod on the /health path (millicores, mean of run means)

CPU limits in the manifests: fastapi 1000 m, gateway 500 m (1000 m in the c5-gateway-cpu1000 configurations), traefik none. A pod at its limit is throttled by the kernel.
With more than one replica the value is the sum over all replicas.
Pods that are not on the request path of a configuration show '-'.

| Config | Rate req/s | fastapi m | gateway m | traefik m |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 94 | - | - |
| c0-baseline | 60 | 105 | - | - |
| c0-baseline | 70 | 117 | - | - |
| c0-baseline | 80 | 133 | - | - |
| c0-baseline | 90 | 145 | - | - |
| c0-baseline | 100 | 159 | - | - |
| c0-baseline | 150 | 223 | - | - |
| c0-baseline | 200 | 292 | - | - |
| c5-gateway | 50 | 84 | 147 | - |
| c5-gateway | 60 | 95 | 178 | - |
| c5-gateway | 70 | 116 | 210 | - |
| c5-gateway | 80 | 132 | 243 | - |
| c5-gateway | 90 | 150 | 279 | - |
| c5-gateway | 100 | 169 | 309 | - |
| c6-all | 50 | 104 | 189 | 48 |
| c6-all | 60 | 136 | 250 | 62 |
| c6-all | 70 | 147 | 264 | 64 |
| c6-all | 80 | 176 | 310 | 73 |
| c6-all | 90 | 201 | 381 | 91 |
| c6-all | 100 | 214 | 379 | 92 |

### Memory per pod on the /health path (Mi, mean of run means)

With more than one replica the value is the sum over all replicas.

| Config | Rate req/s | fastapi Mi | gateway Mi | traefik Mi |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 56 | - | - |
| c0-baseline | 60 | 56 | - | - |
| c0-baseline | 70 | 56 | - | - |
| c0-baseline | 80 | 56 | - | - |
| c0-baseline | 90 | 57 | - | - |
| c0-baseline | 100 | 57 | - | - |
| c0-baseline | 150 | 57 | - | - |
| c0-baseline | 200 | 58 | - | - |
| c5-gateway | 50 | 47 | 48 | - |
| c5-gateway | 60 | 47 | 48 | - |
| c5-gateway | 70 | 47 | 48 | - |
| c5-gateway | 80 | 48 | 48 | - |
| c5-gateway | 90 | 48 | 48 | - |
| c5-gateway | 100 | 48 | 48 | - |
| c6-all | 50 | 49 | 48 | 96 |
| c6-all | 60 | 49 | 48 | 97 |
| c6-all | 70 | 49 | 48 | 97 |
| c6-all | 80 | 49 | 48 | 99 |
| c6-all | 90 | 50 | 51 | 105 |
| c6-all | 100 | 50 | 50 | 100 |

### /chat per number of virtual users

| Config | VUs | Throughput req/s | Avg ms | P95 ms | P99 ms | Failed % | Tokens/s | Runs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 1 | 0.334 | 1997.59 (1958.91-2046.68) | 2124.95 | 2329.10 | 0.00 | 20.1 | 3 |
| c0-baseline | 2 | 0.477 | 3166.87 (3045.91-3242.96) | 3361.42 | 3618.79 | 0.00 | 19.3 | 3 |
| c0-baseline | 4 | 0.483 | 7145.48 (6951.10-7279.21) | 7657.17 | 7944.92 | 0.00 | 19.6 | 3 |
| c6-all | 1 | 0.325 | 2088.90 (1946.29-2365.04) | 2278.86 | 2404.45 | 0.00 | 19.4 | 3 |
| c6-all | 2 | 0.453 | 3412.06 (3059.47-3811.87) | 3940.18 | 4406.11 | 0.00 | 18.5 | 3 |
| c6-all | 4 | 0.460 | 7605.61 (7033.82-8713.20) | 8065.78 | 8295.35 | 0.00 | 18.7 | 3 |

