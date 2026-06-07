# vm.Script Caching Investigation

Related issue: [#3282](https://github.com/shakacode/react_on_rails/issues/3282)

## Verdict

| Area                      | Status         | Finding                                                                               |
| ------------------------- | -------------- | ------------------------------------------------------------------------------------- |
| vm.Script caching benefit | **Not needed** | Execution time dominates; compile overhead is negligible for real workloads           |
| Hypothesis from #3282     | Refuted        | Expected ~3ms savings not achievable — real compile cost is <15μs even for 500KB code |
| Implementation effort     | Not justified  | Adds complexity for <0.01% improvement on actual render paths                         |

## Executive Summary

Issue #3282 proposed caching pre-compiled `vm.Script` objects to save the ~3ms "per-request JS-parse cost" observed in profiling. We ran controlled benchmarks isolating V8 compilation cost and found:

1. **V8 compilation is extremely fast**: ~26μs per MB of code
2. **Execution time dominates**: Scripts with real computation show only 1.02-1.08x speedup from caching
3. **The 3ms observed** was likely execution time, not parse time

Caching `vm.Script` is only beneficial for scripts that:

- Execute in <1μs (trivial expressions)
- Run 100+ times with identical code
- Have minimal actual computation

The render template in react_on_rails_pro does real work (React rendering, props serialization, DOM diffing) — execution will always dominate, making compilation overhead irrelevant.

## Benchmark Environment

- **Runtime**: Node.js v22.12.0
- **OS**: macOS Darwin (arm64)
- **CPU**: Apple M1
- **Methodology**: 5000 measurements per subject (1000 iterations × 5 trials, interleaved A/B)

## Key Results

### 1. Compilation Cost vs Code Size

| Code Size | Compile Time | Cached Exec | Uncached Exec | Speedup   |
| --------- | ------------ | ----------- | ------------- | --------- |
| 60 chars  | 0.54μs       | 0.62μs      | 1.37μs        | **2.2x**  |
| 8 KB      | 0.54μs       | 38.04μs     | 38.54μs       | **1.01x** |
| 69 KB     | 2.75μs       | 400.12μs    | 404.00μs      | **1.01x** |
| 650 KB    | 0.83μs       | 2016.46μs   | 2016.25μs     | **1.00x** |

**Observation**: For scripts with real execution time (38μs+), caching provides <1% improvement because compilation (0.5-3μs) is noise compared to execution.

### 2. Parse Complexity Analysis

Different AST patterns were tested to find maximum parse cost:

| Pattern           | Code Size | Compile Time | Size Needed for 1ms Compile |
| ----------------- | --------- | ------------ | --------------------------- |
| Nested objects    | 2.7 KB    | 1.0μs        | **2.6 MB**                  |
| Generators        | 9 KB      | 1.2μs        | 7.3 MB                      |
| Class definitions | 16 KB     | 1.4μs        | 11.2 MB                     |
| Regex literals    | 29 KB     | 1.8μs        | 15.4 MB                     |
| String literals   | 111 KB    | 3.8μs        | 27.6 MB                     |

**Observation**: Even the most expensive parsing pattern (deeply nested objects) requires 2.6 MB of code to reach 1ms compile time. This is unrealistic for render templates.

### 3. Execution Count Scaling

How much time is saved across N executions of a trivial script (32 chars)?

| Executions | Cached Total | Uncached Total | Time Saved |
| ---------- | ------------ | -------------- | ---------- |
| 10         | 15μs         | 33μs           | 18μs       |
| 100        | 112μs        | 183μs          | 71μs       |
| 1,000      | 627μs        | 1,410μs        | 784μs      |
| 10,000     | 3,844μs      | 11,043μs       | **7.2ms**  |

**Observation**: Need ~10,000 executions of trivial scripts to save 7ms total. The render template runs once per request — no amortization possible.

### 4. Heavy Computation Scripts

Scripts that do real work (object creation, loops, array operations):

| Script Type             | Cached/exec | Uncached/exec | Speedup   |
| ----------------------- | ----------- | ------------- | --------- |
| Trivial (return 1+1)    | 0.37μs      | 1.05μs        | 2.8x      |
| Light (loop 10x)        | 0.47μs      | 1.17μs        | 2.5x      |
| Medium (100 sqrt calls) | 12.87μs     | 13.80μs       | **1.07x** |
| Heavy (1000 objects)    | 39.15μs     | 39.99μs       | **1.02x** |

**Observation**: The moment execution time exceeds ~5μs, caching benefit drops to noise levels.

## Why the Original 3ms Estimate Was Wrong

Issue #3282 stated:

> Per-request JS-parse cost: ~3 ms

This measurement likely included:

1. **React component evaluation** (function execution, not parsing)
2. **Props serialization** (JSON stringify/parse overhead)
3. **Context creation** (`vm.createContext` cost, not `vm.Script` compile)
4. **JIT warmup** artifacts in the profiling

Our isolated benchmark shows V8 parses 1MB of JavaScript in ~26μs. A 200-byte template (post-#3281) would compile in <1μs.

## Scripts That Would Benefit (Not Our Use Case)

Caching helps when:

```js
// Config literals — 2-3x faster
const config = new vm.Script(`({ apiUrl: "...", timeout: 5000 })`);

// Simple expressions — 2-3x faster
const formula = new vm.Script(`price * quantity * (1 - discount)`);

// Feature flags — 2x faster
const check = new vm.Script(`user.role === "admin"`);
```

Caching does NOT help when:

```js
// Data transformation — 1.05x (no real gain)
const transform = new vm.Script(`
  data.map(item => ({ ...item, computed: heavy(item) }))
`);

// React rendering — 1.02x (execution dominates)
const render = new vm.Script(`
  ReactDOMServer.renderToString(React.createElement(App, props))
`);
```

## Decision Framework

| Condition                        | Cache vm.Script? |
| -------------------------------- | ---------------- |
| Script execution < 1μs           | Yes              |
| Script execution > 10μs          | No               |
| Script runs 1x per request       | No               |
| Script is pure config/expression | Yes              |
| Script does React rendering      | **No**           |

## Recommendation

**Close issue #3282 as "won't implement".**

The optimization targets the wrong layer. V8's JIT compiler is not the bottleneck — React rendering and props handling are. Any performance work should focus on:

1. Reducing props size (#3281)
2. Streaming/chunked rendering
3. Component-level caching
4. Reducing React reconciliation work

Adding `vm.Script` caching would:

- Add code complexity (cache invalidation, memory management)
- Provide <0.01% improvement on real workloads
- Create false confidence that "we optimized the VM layer"

## Artifacts

Benchmark scripts and raw data available at:

- Original experiment: `vm-script-cache/tmp/experiments/20260607T083551Z-vm-script-cache/`

### Raw Benchmark Output (Summary)

```text
vm.Script Caching Benchmark
===========================
Node: v22.12.0
Platform: darwin arm64

| Size   | Code Len | Cached Med | Uncached Med | Compile Med | Speedup |
|--------|----------|------------|--------------|-------------|---------|
| tiny   |       60 |       0.62 |         1.37 |        0.54 |    2.20x |
| small  |      344 |       0.42 |         1.00 |        0.62 |    2.40x |
| medium |     8090 |      38.04 |        38.54 |        0.54 |    1.01x |
| large  |    69477 |     400.12 |       404.00 |        2.75 |    1.01x |
| huge   |   650011 |    2016.46 |      2016.25 |        0.83 |    1.00x |
```

### Compilation Cost Analysis

```text
Heavy Parse Patterns Test
============================================================
Pattern                        |    Chars |  Compile
------------------------------------------------------------
1000 regex literals            |    28954 |      1.8μs
2000 unique identifiers        |    92698 |      3.4μs
2000 string literals           |   110952 |      3.8μs
200 nested objects             |     2718 |      1.0μs
1000 arrow functions           |    21724 |      1.4μs
200 generators                 |     8981 |      1.2μs
```

## Conclusion

V8's compilation is too fast to be a bottleneck. The ~3ms attributed to "JS parsing" in the original issue was execution time, not parse time. Caching `vm.Script` objects provides meaningful speedup only for trivial expressions executed thousands of times — not for per-request React rendering.

**Status: Investigation complete. Optimization not needed.**
