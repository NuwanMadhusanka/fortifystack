// FortifyStack load test.
// Ramps traffic to trigger Auto Scaling, then holds to observe steady state.
//
//   Install k6: https://k6.io/docs/get-started/installation/
//   Run:  k6 run -e TARGET=http://<alb-dns-name> load/k6-script.js
//
// Watch in parallel: the CloudWatch dashboard (ASG CPU climbing, then extra
// instances appearing) and the app page (serving instance/AZ rotating).

import http from "k6/http";
import { check, sleep } from "k6";

const TARGET = __ENV.TARGET || "http://localhost:8080";

export const options = {
  stages: [
    { duration: "2m", target: 50 },   // ramp up
    { duration: "5m", target: 200 },  // push CPU past the 50% scaling target
    { duration: "3m", target: 200 },  // hold - ASG should have scaled out
    { duration: "2m", target: 0 },    // ramp down - ASG scales back in
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],          // <1% errors
    http_req_duration: ["p(95)<800"],        // p95 under 800ms
  },
};

export default function () {
  const res = http.get(`${TARGET}/`);
  check(res, {
    "status is 200": (r) => r.status === 200,
    "served by an instance": (r) => r.body && r.body.includes("Serving instance"),
  });
  sleep(1);
}
