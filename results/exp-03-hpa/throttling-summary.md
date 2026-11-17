### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 3 | 2.3 | 48.0 |
| c5-gateway-cpu1000-hpa | step | 3 | 11.1 | 34.4 |
| c5-gateway-cpu1000-r3 | step | 3 | 0.0 | 0.0 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000-hpa | step | 3 | 0.0 | 0.2 |
| c5-gateway-cpu1000-r3 | step | 3 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 3 | 20.8 | 20.9 | 0.0 |
| c5-gateway-cpu1000-hpa | step | 3 | 21.1 | 21.3 | 0.0 |
| c5-gateway-cpu1000-r3 | step | 3 | 21.3 | 21.4 | 0.0 |

