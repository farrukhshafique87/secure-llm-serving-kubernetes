### /health latency per phase (ms)

pre 0-180 s, surge 180-250 s, high 250-490 s, post 490-740 s. Median and p99 per run.

| Config | Rep | Run | Dropped | pre med / p99 | surge med / p99 | high med / p99 | post med / p99 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 1 | collapse | 7599 | 4.69 / 14 | 4.59 / 299 | 5.19 / 3781 | 4.63 / 3561 |
| c5-gateway-cpu1000 | 2 | transient | 20 | 4.50 / 11 | 5.27 / 907 | 5.11 / 594 | 4.55 / 117 |
| c5-gateway-cpu1000 | 3 | transient | 40 | 4.50 / 9 | 4.98 / 1030 | 4.99 / 708 | 4.43 / 20 |
| c5-gateway-cpu1000-hpa | 1 | collapse | 37194 | 4.49 / 11 | 7.12 / 4125 | 3454.43 / 4255 | 5.67 / 59998 |
| c5-gateway-cpu1000-hpa | 2 | collapse | 34628 | 4.58 / 10 | 5.90 / 3920 | 3452.50 / 4249 | 4.62 / 3517 |
| c5-gateway-cpu1000-hpa | 3 | collapse | 33495 | 4.49 / 10 | 27.17 / 3765 | 2931.28 / 3731 | 4.64 / 3019 |
| c5-gateway-cpu1000-r3 | 1 | stable | 0 | 4.42 / 10 | 4.63 / 30 | 4.68 / 33 | 4.39 / 11 |
| c5-gateway-cpu1000-r3 | 2 | stable | 0 | 4.52 / 11 | 4.69 / 61 | 4.69 / 34 | 4.53 / 11 |
| c5-gateway-cpu1000-r3 | 3 | stable | 0 | 4.37 / 9 | 4.57 / 24 | 4.61 / 34 | 4.44 / 10 |

### Median per phase over the runs (ms, median of run medians)

| Config | Runs | pre ms | surge ms | high ms | post ms |
| --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 3 | 4.50 | 4.98 | 5.11 | 4.55 |
| c5-gateway-cpu1000-r3 | 3 | 4.42 | 4.63 | 4.68 | 4.44 |
| c5-gateway-cpu1000-hpa | 3 | 4.49 | 7.12 | 3452.50 | 4.64 |

### Replicas (s after start; step up at 180 s, down at 490-500 s)

Ready replicas from *.replicas.txt (5 s samples); times only for configurations with an HPA. Gateway CPU in the high phase from *.resources.txt: pods present at the start and pods added later, each summed.

| Config | Rep | gateway >= 2 | gateway 3 | gateway max | fastapi max | all back to 1 | gateway pods at start m | gateway added pods m |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 1 | - | - | 1 | 1 | - | 746 | - |
| c5-gateway-cpu1000 | 2 | - | - | 1 | 1 | - | 735 | - |
| c5-gateway-cpu1000 | 3 | - | - | 1 | 1 | - | 726 | - |
| c5-gateway-cpu1000-hpa | 1 | 231 | 231 | 3 | 2 | 595 | 995 | 4 |
| c5-gateway-cpu1000-hpa | 2 | 234 | 234 | 3 | 2 | 581 | 992 | 4 |
| c5-gateway-cpu1000-hpa | 3 | 222 | 222 | 3 | 2 | 569 | 996 | 4 |
| c5-gateway-cpu1000-r3 | 1 | - | - | 3 | 3 | - | 714 | - |
| c5-gateway-cpu1000-r3 | 2 | - | - | 3 | 3 | - | 707 | - |
| c5-gateway-cpu1000-r3 | 3 | - | - | 3 | 3 | - | 704 | - |

