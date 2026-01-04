/**
 * k6 benchmark script for React on Rails
 *
 * This script is designed to be reusable across different routes and configurations.
 * Configuration is passed via environment variables (using -e flag):
 *
 * Required:
 *   TARGET_URL - The full URL to benchmark (e.g., http://localhost:3001/server_side_hello_world)
 *
 * Optional:
 *   RATE - Requests per second ("max" for maximum throughput, or a number). Default: "max"
 *   DURATION - Test duration (e.g., "30s", "1m"). Default: "30s"
 *   CONNECTIONS - Number of concurrent connections/VUs. Default: 10
 *   MAX_CONNECTIONS - Maximum VUs (for constant-arrival-rate). Default: same as CONNECTIONS
 *   REQUEST_TIMEOUT - Request timeout (e.g., "60s"). Default: "60s"
 *
 * Usage:
 *   k6 run -e TARGET_URL=http://localhost:3001/my_route benchmarks/k6.ts
 *   k6 run -e TARGET_URL=http://localhost:3001/my_route -e RATE=100 -e DURATION=1m benchmarks/k6.ts
 */
/* eslint-disable import/no-unresolved -- k6 is installed globally */
import http from 'k6/http';
import { Options, Scenario } from 'k6/options';
import { check } from 'k6';

// Read configuration from environment variables
const targetUrl = __ENV.TARGET_URL;
const rate = __ENV.RATE || 'max';
const duration = __ENV.DURATION || '30s';
const vus = parseInt(__ENV.CONNECTIONS || '10', 10);
const maxVUs = __ENV.MAX_CONNECTIONS ? parseInt(__ENV.MAX_CONNECTIONS, 10) : vus;
const requestTimeout = __ENV.REQUEST_TIMEOUT || '60s';

if (!targetUrl) {
  throw new Error('TARGET_URL environment variable is required');
}

// Configure scenarios based on rate mode
const scenarios: Record<string, Scenario> =
  rate === 'max'
    ? {
        max_rate: {
          executor: 'constant-vus',
          vus,
          duration,
        },
      }
    : {
        constant_rate: {
          executor: 'constant-arrival-rate',
          rate: parseInt(rate, 10) || 50, // same default as in bench.rb
          timeUnit: '1s',
          duration,
          preAllocatedVUs: vus,
          maxVUs,
        },
      };

export const options: Options = {
  // "Highly recommended" in https://grafana.com/docs/k6/latest/using-k6/k6-options/reference/#discard-response-bodies
  discardResponseBodies: true,
  scenarios,
  // Disable default thresholds to avoid noise in output
  thresholds: {},
};

export default () => {
  const response = http.get(targetUrl, {
    timeout: requestTimeout,
    redirects: 0,
  });

  // Check for various status codes to get accurate reporting
  check(response, {
    status_200: (r) => r.status === 200,
    status_3xx: (r) => r.status >= 300 && r.status < 400,
    status_4xx: (r) => r.status >= 400 && r.status < 500,
    status_5xx: (r) => r.status >= 500,
  });
};
