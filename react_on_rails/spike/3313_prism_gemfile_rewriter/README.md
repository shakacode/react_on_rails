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

```
cd react_on_rails
bundle exec rspec spike/3313_prism_gemfile_rewriter/prism_gemfile_rewriter_spec.rb
bundle exec ruby spike/3313_prism_gemfile_rewriter/benchmark.rb
```

## Decision record

See [`DECISION.md`](./DECISION.md).
