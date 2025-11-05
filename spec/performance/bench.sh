#!/usr/bin/env bash
set -euo pipefail
#set -x # Uncomment for debugging commands

# Benchmark parameters
TARGET="http://${BASE_URL:-localhost:3001}/${ROUTE:-server_side_hello_world_hooks}"
# requests per second; if "max" will get maximum number of queries instead of a fixed rate
RATE=${RATE:-50}
# virtual users for k6
VUS=${VUS:-100}
DURATION_SEC=${DURATION_SEC:-10}
DURATION="${DURATION_SEC}s"
# request timeout (duration string like "60s", "1m", "90s")
REQUEST_TIMEOUT=${REQUEST_TIMEOUT:-60s}
# Tools to run (comma-separated)
TOOLS=${TOOLS:-fortio,vegeta,k6}

# Validate input parameters
if ! { [ "$RATE" = "max" ] || { [[ "$RATE" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(bc -l <<< "$RATE > 0") )); }; }; then
  echo "Error: RATE must be 'max' or a positive number (got: '$RATE')" >&2
  exit 1
fi
if ! { [[ "$VUS" =~ ^[0-9]+$ ]] && [ "$VUS" -gt 0 ]; }; then
  echo "Error: VUS must be a positive integer (got: '$VUS')" >&2
  exit 1
fi
if ! { [[ "$DURATION_SEC" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(bc -l <<< "$DURATION_SEC > 0") )); }; then
  echo "Error: DURATION_SEC must be a positive number (got: '$DURATION_SEC')" >&2
  exit 1
fi
if ! [[ "$REQUEST_TIMEOUT" =~ ^([0-9]+(\.[0-9]+)?[smh])+$ ]]; then
  echo "Error: REQUEST_TIMEOUT must be a duration like '60s', '1m', '1.5m' (got: '$REQUEST_TIMEOUT')" >&2
  exit 1
fi

OUTDIR="bench_results"

# Precompute checks for each tool
RUN_FORTIO=0
RUN_VEGETA=0
RUN_K6=0
[[ ",$TOOLS," == *",fortio,"* ]] && RUN_FORTIO=1
[[ ",$TOOLS," == *",vegeta,"* ]] && RUN_VEGETA=1
[[ ",$TOOLS," == *",k6,"* ]] && RUN_K6=1

for cmd in ${TOOLS//,/ } jq column awk tee bc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required tool '$cmd' is not installed" >&2
    exit 1
  fi
done

TIMEOUT_SEC=60
START=$(date +%s)
until curl -fsS "$TARGET" >/dev/null; do
  if (( $(date +%s) - START > TIMEOUT_SEC )); then
    echo "Error: Target $TARGET not responding within ${TIMEOUT_SEC}s" >&2
    exit 1
  fi
  sleep 1
done

echo "Warming up server with 10 requests..."
for i in {1..10}; do
  curl -fsS "$TARGET" >/dev/null || true
  sleep 0.5
done
echo "Warm-up complete"

mkdir -p "$OUTDIR"

if [ "$RATE" = "max" ]; then
  FORTIO_ARGS=(-qps 0)
  VEGETA_ARGS=(-rate=infinity)
  K6_SCENARIOS="{
    max_rate: {
      executor: 'shared-iterations',
      vus: $VUS,
      iterations: $((VUS * DURATION_SEC * 10)),
      maxDuration: '$DURATION'
    }
  }"
else
  FORTIO_ARGS=(-qps "$RATE" -uniform)
  VEGETA_ARGS=(-rate="$RATE")
  K6_SCENARIOS="{
    constant_rate: {
      executor: 'constant-arrival-rate',
      rate: $RATE,
      timeUnit: '1s',
      duration: '$DURATION',
      preAllocatedVUs: $VUS,
      maxVUs: $((VUS * 10))
    }
  }"
fi

if (( RUN_FORTIO )); then
  echo "===> Fortio"
  # TODO https://github.com/fortio/fortio/wiki/FAQ#i-want-to-get-the-best-results-what-flags-should-i-pass
  fortio load "${FORTIO_ARGS[@]}" -t "$DURATION" -timeout "$REQUEST_TIMEOUT" -json "$OUTDIR/fortio.json" "$TARGET" \
    | tee "$OUTDIR/fortio.txt"
fi

if (( RUN_VEGETA )); then
  echo
  echo "===> Vegeta"
  echo "GET $TARGET" | vegeta attack "${VEGETA_ARGS[@]}" -duration="$DURATION" -timeout="$REQUEST_TIMEOUT" \
    | tee "$OUTDIR/vegeta.bin" \
    | vegeta report | tee "$OUTDIR/vegeta.txt"
  vegeta report -type=json "$OUTDIR/vegeta.bin" > "$OUTDIR/vegeta.json"
fi

if (( RUN_K6 )); then
  echo
  echo "===> k6"
  cat <<EOF > "$OUTDIR/k6_test.js"
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: $K6_SCENARIOS,
  httpReq: {
    timeout: '$REQUEST_TIMEOUT',
  },
};

export default function () {
  const response = http.get('$TARGET');
  check(response, {
    'status=200': r => r.status === 200,
    // you can add more if needed:
    // 'status=500': r => r.status === 500,
  });
}
EOF

  k6 run --summary-export="$OUTDIR/k6_summary.json" --summary-trend-stats "min,avg,med,max,p(90),p(99)" "$OUTDIR/k6_test.js" | tee "$OUTDIR/k6.txt"
fi

echo
echo "===> Parsing results and generating summary"

echo -e "Tool\tRPS\tp50(ms)\tp90(ms)\tp99(ms)\tStatus" > "$OUTDIR/summary.txt"

if (( RUN_FORTIO )); then
  FORTIO_RPS=$(jq '.ActualQPS' "$OUTDIR/fortio.json" | awk '{printf "%.2f", $1}')
  FORTIO_P50=$(jq '.DurationHistogram.Percentiles[] | select(.Percentile==50) | .Value * 1000' "$OUTDIR/fortio.json" | awk '{printf "%.2f", $1}')
  FORTIO_P90=$(jq '.DurationHistogram.Percentiles[] | select(.Percentile==90) | .Value * 1000' "$OUTDIR/fortio.json" | awk '{printf "%.2f", $1}')
  FORTIO_P99=$(jq '.DurationHistogram.Percentiles[] | select(.Percentile==99) | .Value * 1000' "$OUTDIR/fortio.json" | awk '{printf "%.2f", $1}')
  FORTIO_STATUS=$(jq -r '.RetCodes | to_entries | map("\(.key)=\(.value)") | join(",")' "$OUTDIR/fortio.json")
  echo -e "Fortio\t$FORTIO_RPS\t$FORTIO_P50\t$FORTIO_P90\t$FORTIO_P99\t$FORTIO_STATUS" >> "$OUTDIR/summary.txt"
fi

if (( RUN_VEGETA )); then
  # .throughput is successful_reqs/total_period, .rate is all_requests/attack_period
  VEGETA_RPS=$(jq '.throughput' "$OUTDIR/vegeta.json" | awk '{printf "%.2f", $1}')
  VEGETA_P50=$(jq '.latencies["50th"] / 1000000' "$OUTDIR/vegeta.json" | awk '{printf "%.2f", $1}')
  VEGETA_P90=$(jq '.latencies["90th"] / 1000000' "$OUTDIR/vegeta.json" | awk '{printf "%.2f", $1}')
  VEGETA_P99=$(jq '.latencies["99th"] / 1000000' "$OUTDIR/vegeta.json" | awk '{printf "%.2f", $1}')
  VEGETA_STATUS=$(jq -r '.status_codes | to_entries | map("\(.key)=\(.value)") | join(",")' "$OUTDIR/vegeta.json")
  echo -e "Vegeta\t$VEGETA_RPS\t$VEGETA_P50\t$VEGETA_P90\t$VEGETA_P99\t$VEGETA_STATUS" >> "$OUTDIR/summary.txt"
fi

if (( RUN_K6 )); then
  K6_RPS=$(jq '.metrics.iterations.rate' "$OUTDIR/k6_summary.json" | awk '{printf "%.2f", $1}')
  K6_P50=$(jq '.metrics.http_req_duration.med' "$OUTDIR/k6_summary.json" | awk '{printf "%.2f", $1}')
  K6_P90=$(jq '.metrics.http_req_duration["p(90)"]' "$OUTDIR/k6_summary.json" | awk '{printf "%.2f", $1}')
  K6_P99=$(jq '.metrics.http_req_duration["p(99)"]' "$OUTDIR/k6_summary.json" | awk '{printf "%.2f", $1}')
  # Status: compute successful vs failed requests
  K6_REQS_TOTAL=$(jq '.metrics.http_reqs.count' "$OUTDIR/k6_summary.json")
  K6_STATUS=$(jq -r '
    .root_group.checks
    | to_entries
    | map(.key[7:] + "=" + (.value.passes|tostring))
    | join(",")
  ' "$OUTDIR/k6_summary.json")
  K6_REQS_KNOWN_STATUS=$(jq -r '
    .root_group.checks
    | to_entries
    | map(.value.passes)
    | add
  ' "$OUTDIR/k6_summary.json")
  K6_REQS_OTHER=$(( K6_REQS_TOTAL - K6_REQS_KNOWN_STATUS ))
  if [ "$K6_REQS_OTHER" -gt 0 ]; then
    K6_STATUS="$K6_STATUS,other=$K6_REQS_OTHER"
  fi
  echo -e "k6\t$K6_RPS\t$K6_P50\t$K6_P90\t$K6_P99\t$K6_STATUS" >> "$OUTDIR/summary.txt"
fi

echo
echo "Summary saved to $OUTDIR/summary.txt"
column -t -s $'\t' "$OUTDIR/summary.txt"
