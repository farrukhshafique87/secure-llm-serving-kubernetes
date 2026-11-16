### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 200 | 1 | 1.7 | 8.3 |
| c5-gateway-cpu1000-r2 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 1 | 0.0 | 0.2 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c0-baseline | 100 | 1 | 0.0 | 0.0 |
| c0-baseline | 150 | 1 | 0.0 | 0.0 |
| c0-baseline | 200 | 1 | 0.1 | 0.2 |
| c0-baseline-r2 | 100 | 1 | 0.0 | 0.0 |
| c0-baseline-r2 | 150 | 1 | 0.0 | 0.0 |
| c0-baseline-r2 | 200 | 1 | 0.0 | 0.0 |
| c0-baseline-r3 | 100 | 1 | 0.0 | 0.0 |
| c0-baseline-r3 | 150 | 1 | 0.0 | 0.0 |
| c0-baseline-r3 | 200 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 200 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 100 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 1 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 100 | 1 | 14.2 | 14.2 | 0.0 |
| c0-baseline | 150 | 1 | 17.0 | 17.0 | 0.0 |
| c0-baseline | 200 | 1 | 19.4 | 19.4 | 0.0 |
| c0-baseline-r2 | 100 | 1 | 13.5 | 13.5 | 0.0 |
| c0-baseline-r2 | 150 | 1 | 17.0 | 17.0 | 0.0 |
| c0-baseline-r2 | 200 | 1 | 21.8 | 21.8 | 0.0 |
| c0-baseline-r3 | 100 | 1 | 13.4 | 13.4 | 0.0 |
| c0-baseline-r3 | 150 | 1 | 15.6 | 15.6 | 0.0 |
| c0-baseline-r3 | 200 | 1 | 17.4 | 17.4 | 0.0 |
| c5-gateway-cpu1000 | 100 | 1 | 21.7 | 21.7 | 0.0 |
| c5-gateway-cpu1000 | 150 | 1 | 26.3 | 26.3 | 0.0 |
| c5-gateway-cpu1000 | 200 | 1 | 31.1 | 31.1 | 0.0 |
| c5-gateway-cpu1000-r2 | 100 | 1 | 21.2 | 21.2 | 0.0 |
| c5-gateway-cpu1000-r2 | 150 | 1 | 26.1 | 26.1 | 0.0 |
| c5-gateway-cpu1000-r2 | 200 | 1 | 31.9 | 31.9 | 0.0 |
| c5-gateway-cpu1000-r3 | 100 | 1 | 22.8 | 22.8 | 0.0 |
| c5-gateway-cpu1000-r3 | 150 | 1 | 26.9 | 26.9 | 0.0 |
| c5-gateway-cpu1000-r3 | 200 | 1 | 32.9 | 32.9 | 0.0 |

