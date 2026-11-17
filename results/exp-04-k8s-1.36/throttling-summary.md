### CPU throttling of `gateway` (share of CFS periods)

Mean: average over runs of the per-run mean. Max: highest 1-minute
value in any run of that level.

| Config | Rate req/s | Runs | Mean % | Max % |
| --- | --- | --- | --- | --- |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 60 | 3 | 0.0 | 0.0 |
| c5-gateway | 70 | 3 | 0.0 | 0.0 |
| c5-gateway | 80 | 3 | 0.1 | 0.5 |
| c5-gateway | 90 | 3 | 1.4 | 5.2 |
| c5-gateway | 100 | 3 | 4.5 | 14.1 |
| c5-gateway-cpu1000 | 50 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 60 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 70 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 80 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 90 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 120 | 3 | 0.0 | 0.2 |
| c5-gateway-cpu1000 | 150 | 3 | 0.2 | 0.9 |

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
| c0-baseline | 120 | 3 | 0.0 | 0.0 |
| c0-baseline | 150 | 3 | 0.0 | 0.0 |
| c5-gateway | 50 | 3 | 0.0 | 0.0 |
| c5-gateway | 60 | 3 | 0.0 | 0.0 |
| c5-gateway | 70 | 3 | 0.0 | 0.0 |
| c5-gateway | 80 | 3 | 0.0 | 0.0 |
| c5-gateway | 90 | 3 | 0.0 | 0.0 |
| c5-gateway | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 50 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 60 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 70 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 80 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 90 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 100 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 120 | 3 | 0.0 | 0.0 |
| c5-gateway-cpu1000 | 150 | 3 | 0.0 | 0.0 |

### Host CPU during the measured run (all CPUs of the WSL host)

| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |
| --- | --- | --- | --- | --- | --- |
| c0-baseline | 50 | 3 | 9.4 | 10.8 | 0.0 |
| c0-baseline | 60 | 3 | 10.2 | 10.3 | 0.0 |
| c0-baseline | 70 | 3 | 10.7 | 10.8 | 0.0 |
| c0-baseline | 80 | 3 | 11.2 | 11.4 | 0.0 |
| c0-baseline | 90 | 3 | 12.8 | 15.6 | 0.0 |
| c0-baseline | 100 | 3 | 13.3 | 16.6 | 0.0 |
| c0-baseline | 120 | 3 | 14.4 | 17.8 | 0.0 |
| c0-baseline | 150 | 3 | 14.8 | 17.6 | 0.0 |
| c5-gateway | 50 | 3 | 13.2 | 14.8 | 0.0 |
| c5-gateway | 60 | 3 | 13.7 | 15.5 | 0.0 |
| c5-gateway | 70 | 3 | 14.9 | 17.2 | 0.0 |
| c5-gateway | 80 | 3 | 15.9 | 18.7 | 0.0 |
| c5-gateway | 90 | 3 | 17.1 | 19.0 | 0.0 |
| c5-gateway | 100 | 3 | 18.2 | 20.2 | 0.0 |
| c5-gateway-cpu1000 | 50 | 3 | 12.0 | 12.5 | 0.0 |
| c5-gateway-cpu1000 | 60 | 3 | 13.0 | 13.1 | 0.0 |
| c5-gateway-cpu1000 | 70 | 3 | 13.9 | 14.3 | 0.0 |
| c5-gateway-cpu1000 | 80 | 3 | 15.0 | 15.3 | 0.0 |
| c5-gateway-cpu1000 | 90 | 3 | 16.2 | 16.9 | 0.0 |
| c5-gateway-cpu1000 | 100 | 3 | 16.8 | 17.2 | 0.0 |
| c5-gateway-cpu1000 | 120 | 3 | 18.9 | 19.5 | 0.0 |
| c5-gateway-cpu1000 | 150 | 3 | 21.7 | 22.7 | 0.0 |

