# Spike: Prism-based Gemfile rewriter for Pro migration (#3313)

Exploratory prototype evaluating whether a Prism AST-based Gemfile rewriter would
reduce maintenance and static-analysis risk vs. the current text/scanner approach
shipped in PR #3232.

**This is not production code.** It is intentionally outside `lib/` to satisfy the
"Do not rewrite #3232 as part of this spike" non-goal in
[issue #3313](https://github.com/shakacode/react_on_rails/issues/3313).

## Files

- `prism_gemfile_rewriter.rb` — the prototype rewriter.
- `prism_gemfile_rewriter_spec.rb` — drives the prototype through the behavior
  matrix from issue #3313 and compares against the current scanner.
- `benchmark.rb` — parse+rewrite perf comparison.

## How to run

```bash
cd react_on_rails
bundle exec rspec spike/3313_prism_gemfile_rewriter/prism_gemfile_rewriter_spec.rb
bundle exec ruby spike/3313_prism_gemfile_rewriter/benchmark.rb
```

### `prism` dependency

The prototype `require`s `prism`. On Ruby 3.3+ `prism` ships with the standard
library, so nothing extra is needed. On Ruby 3.0–3.2 the spike currently relies
on `prism` being present transitively through RuboCop-related dev dependencies
in this monorepo's bundle — `bundle exec` works today, but a future RuboCop
upgrade could drop that transitive dep. If a `LoadError` for `prism` appears,
add `gem "prism"` to `react_on_rails/Gemfile.development_dependencies` (the
spike is intentionally not promoting `prism` to a production runtime dep until
the recommendation in [`DECISION.md`](./DECISION.md) is reconsidered).

## Decision record

See [`DECISION.md`](./DECISION.md).
