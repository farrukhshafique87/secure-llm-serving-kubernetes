### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 150 | 3 | 0.0 | 0.2 |
| c5-gateway-cpu1000 | 200 | 3 | 0.2 | 0.7 |
| c5-gateway-cpu1000-r2 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 3 | 0.1 | 0.3 |
| c5-gateway-cpu1000-r3 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 3 | 0.0 | 0.0 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 3 | 0.0 | 0.0 |
| c0-baseline | 150 | 3 | 0.0 | 0.0 |
| c0-baseline | 200 | 3 | 0.1 | 0.2 |
| c0-baseline-r2 | 100 | 3 | 0.0 | 0.0 |
| c0-baseline-r2 | 150 | 3 | 0.0 | 0.0 |
| c0-baseline-r2 | 200 | 3 | 0.0 | 0.0 |
| c0-baseline-r3 | 100 | 3 | 0.0 | 0.0 |
| c0-baseline-r3 | 150 | 3 | 0.0 | 0.0 |
| c0-baseline-r3 | 200 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 150 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 200 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 3 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 3 | 15.1 | 17.7 | 0.0 |
| c0-baseline | 150 | 3 | 17.8 | 20.6 | 0.0 |
| c0-baseline | 200 | 3 | 18.6 | 18.8 | 0.0 |
| c0-baseline-r2 | 100 | 3 | 16.1 | 17.9 | 0.0 |
| c0-baseline-r2 | 150 | 3 | 18.4 | 21.9 | 0.0 |
| c0-baseline-r2 | 200 | 3 | 20.9 | 24.9 | 0.0 |
| c0-baseline-r3 | 100 | 3 | 14.4 | 15.3 | 0.0 |
| c0-baseline-r3 | 150 | 3 | 16.2 | 16.9 | 0.0 |
| c0-baseline-r3 | 200 | 3 | 18.5 | 18.9 | 0.0 |
| c5-gateway-cpu1000 | 100 | 3 | 19.1 | 20.1 | 0.0 |
| c5-gateway-cpu1000 | 150 | 3 | 23.3 | 24.2 | 0.0 |
| c5-gateway-cpu1000 | 200 | 3 | 28.5 | 29.6 | 0.0 |
| c5-gateway-cpu1000-r2 | 100 | 3 | 19.9 | 20.7 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 3 | 24.7 | 24.9 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 3 | 29.8 | 30.1 | 0.0 |
| c5-gateway-cpu1000-r3 | 100 | 3 | 20.1 | 20.5 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 3 | 24.8 | 25.1 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 3 | 30.8 | 31.1 | 0.0 |

