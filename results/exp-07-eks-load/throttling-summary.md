### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 100 | 3 | 0.0 | 0.0 |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 100 | 3 | 0.0 | 0.0 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 0.0 | 0.0 |
| c0-baseline | 100 | 3 | 0.0 | 0.0 |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 100 | 3 | 0.0 | 0.0 |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 100 | 3 | 0.0 | 0.0 |

### CPU throttling of `linkerd-proxy` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 100 | 3 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 7.6 | 7.7 | 0.0 |
| c0-baseline | 100 | 3 | 8.4 | 8.5 | 0.0 |
| c5-gateway | 50 | 3 | 7.5 | 7.6 | 0.0 |
| c5-gateway | 100 | 3 | 8.6 | 8.7 | 0.0 |
| c6-all | 50 | 3 | 7.6 | 7.7 | 0.0 |
| c6-all | 100 | 3 | 8.5 | 8.5 | 0.0 |

