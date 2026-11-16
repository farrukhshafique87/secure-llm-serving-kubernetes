// EXP-03 HPA part: /health with a load step, so that an autoscaler has
// something to react to. 3 min low, 10 s ramp, 5 min high, 10 s ramp,
// 4 min low (12 min 20 s). Every request is tagged with its phase; the
// thresholds below are always met and only make k6 write the per-phase
// latency into the summary JSON.
import http from 'k6/http';
import exec from 'k6/execution';
import { check } from 'k6';
import { BASE_URL, headers } from './lib/common.js';

const LOW = parseInt(__ENV.LOW_RATE || '20');
const HIGH = parseInt(__ENV.HIGH_RATE || '200');

// Phase boundaries in seconds since the start of the scenario.
//   pre    0-180    low rate before the step
//   surge  180-250  ramp and the first 60 s at the high rate
//   high   250-490  rest of the high rate
//   post   490-740  ramp down and low rate after the step
const PHASES = [
  ['pre', 180],
  ['surge', 250],
  ['high', 490],
  ['post', Infinity],
];

export const options = {
  scenarios: {
    step: {
      executor: 'ramping-arrival-rate',
      startRate: LOW,
      timeUnit: '1s',
      stages: [
        { target: LOW, duration: '3m' },
        { target: HIGH, duration: '10s' },
        { target: HIGH, duration: '5m' },
        { target: LOW, duration: '10s' },
        { target: LOW, duration: '4m' },
      ],
      preAllocatedVUs: parseInt(__ENV.PRE_VUS || '110'),
      maxVUs: parseInt(__ENV.MAX_VUS || '250'),
    },
  },
  thresholds: Object.fromEntries(
    PHASES.map(([name]) => [`http_req_duration{phase:${name}}`, ['max>=0']]),
  ),
};

function phase() {
  const elapsed = (Date.now() - exec.scenario.startTime) / 1000;
  return PHASES.find(([, end]) => elapsed < end)[0];
}

export default function () {
  const params = headers();
  params.tags.phase = phase();
  const res = http.get(`${BASE_URL}/health`, params);
  check(res, { 'status is 200': (r) => r.status === 200 });
}
