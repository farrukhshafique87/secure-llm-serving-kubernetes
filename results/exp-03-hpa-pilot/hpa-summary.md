### /health latency per phase (ms)

pre 0-180 s, surge 180-250 s, high 250-490 s, post 490-740 s. Median and p99 per run.

| Config | Rep | Run | Dropped | pre med / p99 | surge med / p99 | high med / p99 | post med / p99 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 1 | transient | 13 | 4.49 / 9 | 4.39 / 230 | 4.51 / 344 | 4.39 / 10 |
| c5-gateway-cpu1000-hpa | 1 | collapse | 35360 | 4.55 / 13 | 5.83 / 4657 | 3445.08 / 4675 | 4.49 / 3390 |

### Median per phase over the runs (ms, median of run medians)

| Config | Runs | pre ms | surge ms | high ms | post ms |
| --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 1 | 4.49 | 4.39 | 4.51 | 4.39 |
| c5-gateway-cpu1000-hpa | 1 | 4.55 | 5.83 | 3445.08 | 4.49 |

### Replicas (s after start; step up at 180 s, down at 490-500 s)

Ready replicas from *.replicas.txt (5 s samples); times only for configurations with an HPA. Gateway CPU in the high phase from *.resources.txt: pods present at the start and pods added later, each summed.

| Config | Rep | gateway >= 2 | gateway 3 | gateway max | fastapi max | all back to 1 | gateway pods at start m | gateway added pods m |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 1 | - | - | 1 | 1 | - | 651 | - |
| c5-gateway-cpu1000-hpa | 1 | 232 | 244 | 3 | 2 | 591 | 995 | 4 |

