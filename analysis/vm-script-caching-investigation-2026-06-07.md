# vm.Script Caching Investigation

Related issue: [#3282](https://github.com/shakacode/react_on_rails/issues/3282)

## Verdict

| Area                      | Status                                | Finding                                                                                                           |
| ------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| vm.Script caching benefit | **Not supported by current evidence** | Exploratory microbenchmarks show same-source cache hits and colder unique-source compiles behave very differently |
| Hypothesis from #3282     | Not demonstrated as raw compile cost  | The original ~3ms observation was not reproduced with its original harness                                        |
| Implementation effort     | Not justified without stronger signal | Adds cache invalidation and memory-management complexity before a production-like win is proven                   |

## Executive Summary

Issue #3282 proposed caching pre-compiled `vm.Script` objects to save the ~3ms "per-request JS-parse cost" observed in profiling. This note measured isolated `vm.Script` compilation and cached-vs-uncached execution on macOS arm64. It did **not** reproduce the original #3282 profiling harness or a Linux x86_64 production-like environment.

Directly measured in this investigation:

1. **Isolated compile/setup medians need caveats**: original raw medians were 0.5-3.8μs, with a clearly noisy 650 KB row at 0.83μs; a 2026-06-13 reproduction separated hot same-source cache hits from colder unique-source compiles and measured much larger values for the unique-source path, including a 662 KB generated script around 8.8ms on Apple M5 Max.
2. **Execution time dominated these synthetic scripts**: scripts with real computation showed roughly 1.00-1.08x speedup from caching, often within measurement noise.
3. **No portable throughput constant was established**: the measurements are useful as exploratory evidence, not as a precise "μs per MB" claim.

Inferred, not directly measured here:

1. The original ~3ms #3282 observation likely included work other than raw `new vm.Script(...)` compilation, such as React execution, props handling, context setup, or profiler warmup effects.
2. A production-like Linux x86_64 benchmark could still find a meaningful compile/cache signal, but this analysis did not produce that evidence.

Caching `vm.Script` is only beneficial for scripts that:

- Execute in <1μs (trivial expressions)
- Run 100+ times with identical code
- Have minimal actual computation

The render template in react_on_rails_pro does real work (React rendering and props serialization). The available evidence says execution is likely to dominate; it does not prove that every production workload has zero measurable benefit from `vm.Script` caching.

## Original Benchmark Environment

- **Runtime**: Node.js v22.12.0
- **OS**: macOS Darwin (arm64)
- **CPU**: Apple M1
- **Methodology**: 5000 measurements per subject (1000 iterations × 5 trials, interleaved A/B)

## Reproducibility Note

The original local experiment bundle was an ephemeral `tmp/` path and was not retained. A narrow standalone reproduction script is now committed as [`analysis/vm-script-caching-repro-2026-06-13.mjs`](vm-script-caching-repro-2026-06-13.mjs). It is intended to reproduce the shape of the microbenchmark, not to establish portable production throughput.

## Key Results

### 1. Compilation Cost vs Code Size

| Code Size | Compile Time | Cached Exec | Uncached Exec | Speedup   | Interpretation              |
| --------- | ------------ | ----------- | ------------- | --------- | --------------------------- |
| 60 chars  | 0.54μs       | 0.62μs      | 1.37μs        | **2.2x**  | Trivial script              |
| 8 KB      | 0.54μs       | 38.04μs     | 38.54μs       | **1.01x** | Noise-band difference       |
| 69 KB     | 2.75μs       | 400.12μs    | 404.00μs      | **1.01x** | Noise-band difference       |
| 650 KB    | 0.83μs       | 2016.46μs   | 2016.25μs     | **1.00x** | Internally inconsistent row |

**Observation**: For scripts with real execution time (38μs+), cached-vs-uncached differences were mostly <1%. The 650 KB compile median is lower than the 69 KB median, so it should be treated as timer and benchmark noise. This table does not support a precise per-MB compilation-throughput claim.

### 2. Parse Complexity Analysis

Different AST patterns were tested to find maximum parse cost:

| Pattern           | Code Size | Compile Time | Size Needed for 1ms Compile |
| ----------------- | --------- | ------------ | --------------------------- |
| Nested objects    | 2.7 KB    | 1.0μs        | **2.6 MB**                  |
| Generators        | 9 KB      | 1.2μs        | 7.3 MB                      |
| Class definitions | 16 KB     | 1.4μs        | 11.2 MB                     |
| Regex literals    | 29 KB     | 1.8μs        | 15.4 MB                     |
| String literals   | 111 KB    | 3.8μs        | 27.6 MB                     |

**Observation**: These generated AST patterns also landed in the low-microsecond range. The "size needed for 1ms compile" column is a rough extrapolation from noisy microbench data, not a measured production threshold.

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

**Observation**: In these synthetic cases, once execution time exceeded a few microseconds, caching benefit dropped into measurement noise.

## What the Original 3ms Estimate Did and Did Not Show

Issue #3282 stated:

> Per-request JS-parse cost: ~3 ms

This investigation did not rerun the original profiling harness, so it cannot prove what the original number contained. Based on the isolated microbenchmarks above, the ~3ms "parse" attribution likely included one or more non-compile costs:

1. **React component evaluation** (function execution, not parsing)
2. **Props serialization** (JSON stringify/parse overhead)
3. **Context creation** (`vm.createContext` cost, not `vm.Script` compile)
4. **JIT warmup** artifacts in the profiling

The corrected conclusion is narrower: the available isolated measurements did not reproduce a raw `vm.Script` compile cost anywhere near 3ms. They do not, by themselves, prove that a 200-byte post-#3281 render template would always compile in less than 1μs on every runtime and host.

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

**Keep issue #3282 closed unless new production-like evidence shows a material win.**

The current evidence does not justify adding `vm.Script` caching to the renderer. It points toward React rendering and props handling as better performance targets:

1. Reducing props size (#3281)
2. Streaming/chunked rendering
3. Component-level caching
4. Reducing React reconciliation work

Adding `vm.Script` caching without stronger evidence would:

- Add code complexity (cache invalidation, memory management)
- Risk providing no measurable improvement on real workloads
- Create false confidence that "we optimized the VM layer"

## Artifacts

Benchmark scripts and raw data are captured in this committed analysis note:

- Reproduction script: [`analysis/vm-script-caching-repro-2026-06-13.mjs`](vm-script-caching-repro-2026-06-13.mjs)
- Example reproduction output: see the section below.
- Original raw benchmark output: see the two later sections, with caveats.
- Original local experiment bundle: intentionally not retained because it was an ephemeral `tmp/` path.

### Example Reproduction Output (2026-06-13)

Later runs on the same host varied with source shape, V8's compilation cache, and sampling noise; run the script above for current local values.

```text
vm.Script caching reproduction
==============================
Node: v22.12.0
Platform: darwin arm64
CPU: Apple M5 Max

| Size | Code Len | Samples | Same-source Compile | Unique-source Compile | Cached Med | Uncached Med | Speedup |
| ---- | -------- | ------- | ------------------- | --------------------- | ---------- | ------------ | ------- |
| tiny   |       54 |    5000 |              0.46us |                2.62us |     0.88us |       1.17us | 1.33x |
| small  |      379 |    3000 |              0.37us |                6.75us |     1.54us |       2.00us | 1.30x |
| medium |     8323 |    1000 |              0.54us |              106.50us |    25.42us |      26.17us | 1.03x |
| large  |    72453 |     300 |              1.58us |             1190.38us |   207.54us |     208.96us | 1.01x |
| huge   |   662053 |      80 |              9.96us |             8834.42us |  1917.67us |    1958.00us | 1.02x |

Note: Same-source compile uses V8/Node compilation-cache behavior by default.
Unique-source compile varies the source text each sample to show a colder path.
Run with `node --no-compilation-cache` to compare with V8 compilation caching disabled.
```

### Original Raw Benchmark Output (Exploratory)

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

The available microbenchmarks do not support implementing `vm.Script` caching for the render path. They show cached-vs-uncached runtime differences near the measurement-noise band once scripts perform real work, while also showing that cold or unique-source compilation can be much more expensive than the original same-source compile medians implied.

The stronger original wording was overconfident. The ~3ms attributed to "JS parsing" in #3282 was not reproduced here as raw `vm.Script` compile cost, but identifying it as execution time remains an inference until the original or an equivalent production-like harness is rerun.

**Status: Investigation corrected. Optimization still not justified by current evidence.**
