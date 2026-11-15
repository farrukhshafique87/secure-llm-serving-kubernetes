### Lightweight path (/health), no inference

| Config | Avg ms | Δ ms | Δ % | P95 ms | P99 ms | Runs | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 1.99 (1.94-2.03) | - | - | 2.59 | 3.14 | 3 | reference |
| c1-rbac | 2.02 (1.93-2.16) | +0.04 | +1.8 | 2.74 | 3.37 | 3 | within noise |
| c2-netpol | 1.98 (1.97-1.99) | -0.01 | -0.5 | 2.55 | 3.13 | 3 | within noise |
| c3-mtls | 2.22 (2.19-2.27) | +0.23 | +11.8 | 2.94 | 3.75 | 3 | distinct, higher |
| c4-tls | 2.72 (2.70-2.74) | +0.73 | +36.7 | 3.50 | 4.20 | 3 | distinct, higher |
| c5-gateway | 4.19 (4.12-4.23) | +2.20 | +110.6 | 5.48 | 6.91 | 3 | distinct, higher |
| c6-all | 6.38 (6.28-6.48) | +4.39 | +220.9 | 8.40 | 10.59 | 3 | distinct, higher |
A configuration marked "distinct, lower" is faster than the baseline, which cannot be a cost of the control. It shows drift between runs, not overhead.

### Inference path (/chat)

| Config | Avg ms | Δ ms | Δ % | P95 ms | P99 ms | Runs | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 1992.76 (1933.93-2055.34) | - | - | 2152.61 | 2304.54 | 3 | reference |
| c1-rbac | 1971.83 (1952.35-2002.33) | -20.93 | -1.1 | 2175.89 | 2268.65 | 3 | within noise |
| c2-netpol | 2032.83 (1995.97-2066.11) | +40.07 | +2.0 | 2172.98 | 2278.98 | 3 | within noise |
| c3-mtls | 1949.49 (1902.18-2035.95) | -43.27 | -2.2 | 2122.50 | 2408.79 | 3 | within noise |
| c4-tls | 2003.46 (1971.40-2031.78) | +10.70 | +0.5 | 2149.62 | 2242.61 | 3 | within noise |
| c5-gateway | 2023.89 (2002.84-2053.66) | +31.13 | +1.6 | 2210.11 | 2303.90 | 3 | within noise |
| c6-all | 1939.62 (1903.21-1961.39) | -53.14 | -2.7 | 2101.17 | 2403.29 | 3 | within noise |
A configuration marked "distinct, lower" is faster than the baseline, which cannot be a cost of the control. It shows drift between runs, not overhead.

### Resources on the /health path (50 requests/s)

CPU in millicores, memory in MiB; mean over repetitions of the per-run mean.
Only pods that take part in the request path are summed; Linkerd's control
plane counts for the configurations that use the mesh.

| Config | Pods summed | CPU m | Δ CPU m | Memory Mi | Δ Memory Mi |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | fastapi | 88 | - | 53 | - |
| c1-rbac | fastapi | 90 | +2 | 54 | +1 |
| c2-netpol | fastapi | 88 | -0 | 50 | -3 |
| c3-mtls | fastapi, l5d-destination, l5d-identity, l5d-proxy-injector | 112 | +24 | 192 | +139 |
| c4-tls | fastapi, traefik | 134 | +45 | 162 | +109 |
| c5-gateway | fastapi, gateway | 210 | +122 | 105 | +51 |
| c6-all | fastapi, gateway, traefik, l5d-destination, l5d-identity, l5d-proxy-injector | 340 | +251 | 358 | +304 |

