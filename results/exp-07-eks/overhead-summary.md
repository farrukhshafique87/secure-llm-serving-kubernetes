### Lightweight path (/health), no inference

| Config | Avg ms | Δ ms | Δ % | P95 ms | P99 ms | Runs | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 1.55 (1.50-1.58) | - | - | 1.91 | 2.84 | 3 | reference |
| c1-rbac | 1.56 (1.52-1.59) | +0.01 | +0.4 | 1.91 | 2.75 | 3 | within noise |
| c2-netpol | 1.57 (1.53-1.61) | +0.02 | +1.2 | 1.91 | 2.70 | 3 | within noise |
| c3-mtls | 1.96 (1.90-2.05) | +0.41 | +26.2 | 2.47 | 3.78 | 3 | distinct, higher |
| c4-tls | 2.33 (2.31-2.34) | +0.78 | +50.1 | 2.84 | 4.23 | 3 | distinct, higher |
| c5-gateway | 3.74 (3.65-3.80) | +2.19 | +141.5 | 4.61 | 7.19 | 3 | distinct, higher |
| c6-all | 5.18 (5.12-5.29) | +3.64 | +234.6 | 6.44 | 9.75 | 3 | distinct, higher |
A configuration marked "distinct, lower" is faster than the baseline, which cannot be a cost of the control. It shows drift between runs, not overhead.

### Inference path (/chat)

| Config | Avg ms | Δ ms | Δ % | P95 ms | P99 ms | Runs | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline | 1434.30 (1433.55-1434.78) | - | - | 1471.01 | 1573.59 | 3 | reference |
| c1-rbac | 1430.32 (1421.74-1435.30) | -3.98 | -0.3 | 1463.64 | 1544.69 | 3 | within noise |
| c2-netpol | 1429.64 (1423.15-1434.94) | -4.66 | -0.3 | 1457.58 | 1479.98 | 3 | within noise |
| c3-mtls | 1436.30 (1429.43-1445.79) | +2.00 | +0.1 | 1469.42 | 1546.34 | 3 | within noise |
| c4-tls | 1432.51 (1430.27-1434.11) | -1.79 | -0.1 | 1463.41 | 1538.69 | 3 | within noise |
| c5-gateway | 1431.54 (1428.25-1434.02) | -2.76 | -0.2 | 1459.51 | 1518.57 | 3 | within noise |
| c6-all | 1435.46 (1434.31-1436.46) | +1.16 | +0.1 | 1463.67 | 1498.44 | 3 | within noise |
A configuration marked "distinct, lower" is faster than the baseline, which cannot be a cost of the control. It shows drift between runs, not overhead.

### Resources on the /health path (50 requests/s)

CPU in millicores, memory in MiB; mean over repetitions of the per-run mean.
Only pods that take part in the request path are summed; Linkerd's control
plane counts for the configurations that use the mesh.

| Config | Pods summed | CPU m | Δ CPU m | Memory Mi | Δ Memory Mi |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | fastapi | 67 | - | 43 | - |
| c1-rbac | fastapi | 67 | +0 | 43 | -0 |
| c2-netpol | fastapi | 67 | -0 | 43 | +0 |
| c3-mtls | fastapi, l5d-destination, l5d-identity, l5d-proxy-injector | 93 | +26 | 116 | +73 |
| c4-tls | fastapi, traefik | 105 | +38 | 73 | +30 |
| c5-gateway | fastapi, gateway | 176 | +109 | 84 | +41 |
| c6-all | fastapi, gateway, traefik, l5d-destination, l5d-identity, l5d-proxy-injector | 257 | +189 | 191 | +148 |

