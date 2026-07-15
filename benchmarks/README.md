# Benchmarks

Use this directory for benchmark harness code, local dedicated-hardware runs, and hosted
benchmark diagnostics.

## Entry points

- [Local dedicated-hardware benchmarking](LOCAL_BENCHMARK.md) - operator guide for the
  trusted M1/`m1-bench` flow, including quiet A/B comparisons, upload policy, scheduling,
  and what evidence to post.
- [`run-local-benchmark.rb`](run-local-benchmark.rb) - run one suite on the current
  checkout and optionally upload to Bencher.
- [`run-local-benchmark-comparison.rb`](run-local-benchmark-comparison.rb) - compare two
  refs with repeated, quiet-machine A/B runs and local summary artifacts.
- [Benchmark Workflow](../.github/workflows/benchmark.yml) - GitHub-hosted workflow that
  automatically validates benchmark scripts on push and pull request events. The hosted
  benchmark suites inside it are manual-only diagnostics, not the trusted trend source.

For performance claims, prefer the local dedicated-hardware guide. GitHub-hosted runners
remain useful for checking that the workflow and benchmark scripts still execute, but their
numbers are not stable enough for the release trend.
