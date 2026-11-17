### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 1 | 0.4 | 4.0 |
| c5-gateway-cpu1000-hpa | step | 1 | 13.0 | 33.5 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 1 | 0.0 | 0.0 |
| c5-gateway-cpu1000-hpa | step | 1 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c5-gateway-cpu1000 | step | 1 | 19.2 | 19.2 | 0.0 |
| c5-gateway-cpu1000-hpa | step | 1 | 20.9 | 20.9 | 0.0 |

