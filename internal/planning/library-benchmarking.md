# Library Benchmarking Strategy

## Current Approach

We use **max rate benchmarking** - each route is tested at maximum throughput to measure its capacity.

### Configuration

- `RATE=max` - Tests maximum throughput
- `CONNECTIONS=10` - Concurrent connections
- `DURATION=30s` - Test duration per route

## Trade-offs: Max Rate vs Fixed Rate

### Max Rate (Current)

**Pros:**

- Measures actual throughput capacity
- Self-adjusting - no need to maintain per-route rate configs
- Identifies bottlenecks and ceilings

**Cons:**

- Results vary with CI runner performance
- Harder to compare across commits when capacity changes significantly
- Noise from shared CI infrastructure

### Fixed Rate

**Pros:**

- Consistent baseline across runs
- Latency comparisons are meaningful
- Detects regressions at a specific load level

**Cons:**

- Must be set below the slowest route's capacity
- If route capacity changes, historical data becomes incomparable
- Requires maintaining rate configuration per route

## Why We Chose Max Rate

Different routes have vastly different capacities:

- `/empty` - ~1500 RPS
- SSR routes - ~50-200 RPS depending on component complexity

A fixed rate low enough for all routes would under-utilize fast routes. A per-route fixed rate config would be painful to maintain and would break comparisons when capacity changes.

For library benchmarking in CI, we accept some noise and focus on detecting significant regressions (>15-20%).

## Future Considerations

Options to improve accuracy if needed:

1. **Multiple samples** - Run each benchmark 2-3 times, average results, flag high variance
2. **Adaptive rate** - Quick max-rate probe, then benchmark at 70% capacity
3. **Per-route fixed rates** - Maintain target RPS config (high maintenance burden)
4. **Dedicated benchmark runners** - Reduce CI noise with consistent hardware
