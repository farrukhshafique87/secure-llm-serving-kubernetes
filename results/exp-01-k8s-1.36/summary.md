### results/exp-01-k8s-1.36

| Config | Runs | Avg ms | P95 ms | P99 ms | Max ms | Req/s | Failed % | Tokens/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c0-baseline-health | 3 | 1.96 (1.94-1.98) | 2.58 (2.54-2.61) | 3.27 (3.17-3.36) | 25.6 (23.0-30.6) | 50.00 (50.00-50.01) | 0.00 | - |
| c0-baseline | 3 | 2020.13 (1982.74-2092.73) | 2215.71 (2102.92-2439.32) | 2390.65 (2143.72-2667.55) | 3054.3 (2184.3-4384.1) | 0.33 (0.32-0.34) | 0.00 | 19.90 (19.32-20.21) |

| Config | Pod | CPU m (mean of run means) | Memory Mi |
| --- | --- | --- | --- |
| c0-baseline-health | fastapi | 88 (86-90) | 62 (60-62) |
| c0-baseline-health | linkerd-destination | 3 (3-3) | 82 (82-82) |
| c0-baseline-health | linkerd-identity | 1 | 30 |
| c0-baseline-health | linkerd-proxy-injector | 1 (1-1) | 54 (54-54) |
| c0-baseline-health | ollama | 1 (1-1) | 690 (689-690) |
| c0-baseline-health | traefik | 1 (1-1) | 58 (58-59) |
| c0-baseline | fastapi | 10 (10-10) | 58 (51-61) |
| c0-baseline | linkerd-destination | 3 (3-4) | 83 (82-84) |
| c0-baseline | linkerd-identity | 1 (1-1) | 30 (30-30) |
| c0-baseline | linkerd-proxy-injector | 1 (1-1) | 54 (54-55) |
| c0-baseline | ollama | 1678 (1669-1694) | 691 (690-694) |
| c0-baseline | traefik | 1 (1-1) | 59 (58-60) |

