### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 60 | 3 | 0.1 | 0.2 |
| c5-gateway | 70 | 3 | 0.1 | 0.3 |
| c5-gateway | 80 | 3 | 0.3 | 0.9 |
| c5-gateway | 90 | 3 | 2.7 | 4.4 |
| c5-gateway | 100 | 3 | 4.9 | 21.7 |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 60 | 3 | 0.4 | 2.9 |
| c6-all | 70 | 3 | 0.0 | 0.0 |
| c6-all | 80 | 3 | 0.4 | 1.8 |
| c6-all | 90 | 3 | 3.0 | 21.6 |
| c6-all | 100 | 3 | 1.4 | 4.7 |

### CPU throttling of `fastapi` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 0.0 | 0.0 |
| c0-baseline | 60 | 3 | 0.0 | 0.0 |
| c0-baseline | 70 | 3 | 0.0 | 0.0 |
| c0-baseline | 80 | 3 | 0.0 | 0.0 |
| c0-baseline | 90 | 3 | 0.0 | 0.0 |
| c0-baseline | 100 | 3 | 0.0 | 0.0 |
| c0-baseline | 150 | 3 | 0.1 | 0.4 |
| c0-baseline | 200 | 3 | 0.0 | 0.0 |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 60 | 3 | 0.0 | 0.0 |
| c5-gateway | 70 | 3 | 0.0 | 0.0 |
| c5-gateway | 80 | 3 | 0.0 | 0.0 |
| c5-gateway | 90 | 3 | 0.0 | 0.0 |
| c5-gateway | 100 | 3 | 0.0 | 0.0 |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 60 | 3 | 0.0 | 0.0 |
| c6-all | 70 | 3 | 0.0 | 0.0 |
| c6-all | 80 | 3 | 0.0 | 0.0 |
| c6-all | 90 | 3 | 0.0 | 0.0 |
| c6-all | 100 | 3 | 0.0 | 0.0 |

### CPU throttling of `linkerd-proxy` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c6-all | 50 | 3 | 0.0 | 0.0 |
| c6-all | 60 | 3 | 0.0 | 0.0 |
| c6-all | 70 | 3 | 0.0 | 0.0 |
| c6-all | 80 | 3 | 0.0 | 0.1 |
| c6-all | 90 | 3 | 0.0 | 0.0 |
| c6-all | 100 | 3 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 11.7 | 15.7 | 0.0 |
| c0-baseline | 60 | 3 | 10.4 | 10.8 | 0.0 |
| c0-baseline | 70 | 3 | 10.7 | 10.9 | 0.0 |
| c0-baseline | 80 | 3 | 11.1 | 11.3 | 0.0 |
| c0-baseline | 90 | 3 | 11.6 | 11.9 | 0.0 |
| c0-baseline | 100 | 3 | 11.9 | 12.6 | 0.0 |
| c0-baseline | 150 | 3 | 13.7 | 14.3 | 0.0 |
| c0-baseline | 200 | 3 | 16.1 | 16.4 | 0.0 |
| c5-gateway | 50 | 3 | 12.7 | 13.6 | 0.0 |
| c5-gateway | 60 | 3 | 14.5 | 15.5 | 0.0 |
| c5-gateway | 70 | 3 | 15.9 | 16.8 | 0.0 |
| c5-gateway | 80 | 3 | 16.8 | 18.2 | 0.0 |
| c5-gateway | 90 | 3 | 18.2 | 19.5 | 0.0 |
| c5-gateway | 100 | 3 | 19.2 | 20.5 | 0.0 |
| c6-all | 50 | 3 | 14.2 | 16.2 | 0.0 |
| c6-all | 60 | 3 | 17.2 | 17.6 | 0.0 |
| c6-all | 70 | 3 | 17.4 | 19.1 | 0.0 |
| c6-all | 80 | 3 | 20.4 | 22.5 | 0.0 |
| c6-all | 90 | 3 | 21.3 | 22.3 | 0.0 |
| c6-all | 100 | 3 | 21.9 | 23.9 | 0.0 |

