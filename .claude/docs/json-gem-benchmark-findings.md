# JSON Gem Performance Investigation (Issue #3284)

This document summarizes the findings from investigating whether switching from Ruby's stdlib `JSON.generate` to `Oj.dump` would improve performance in React on Rails' render path.

## Background

Issue #3284 hypothesized that switching to Oj for JSON serialization would save 5-10ms per request based on the common belief that Oj is 2-3x faster than stdlib JSON.

## Key Finding: JSON Gem Version Matters More Than Oj

The Ruby `json` gem underwent a major performance rewrite in version 2.8.0 (late 2024). This changes the optimization landscape entirely:

| JSON Gem Version | vs Oj | Notes |
|------------------|-------|-------|
| 2.1.0 (2017) | Oj 5.5x faster | Old wisdom was correct |
| 2.5.1 (2021) | Oj 2.0x faster | Bundled with Ruby 3.0 |
| 2.7.2 (2024) | Oj 1.4x faster | Bundled with Ruby 3.3 |
| **2.8.0+ (2024)** | **JSON 1.5-2x faster** | Crossover point |
| 2.19.8 (2025) | JSON 1.2-2x faster | Latest version |

## Benchmark Results

### With Bundled JSON (what users have by default)

Ruby 3.3 ships with JSON 2.7.2. For a ~3MB payload:

| Method | Time | 
|--------|------|
| JSON.generate | 21.5 ms |
| Oj.dump | 13.4 ms |
| **Savings with Oj** | **8.1 ms (38%)** |

### With Upgraded JSON (gem 'json', '>= 2.8')

Same Ruby 3.3, same ~3MB payload:

| Method | Time |
|--------|------|
| JSON.generate | 10.2 ms |
| Oj.dump | 12.5 ms |
| **Savings with JSON** | **2.3 ms (18%)** |

### Scaling by Payload Size

With bundled JSON 2.7.2:

| Payload | JSON.generate | Oj.dump | Oj Savings |
|---------|---------------|---------|------------|
| 1 MB | 7.6 ms | 5.6 ms | 2.0 ms |
| 4 MB | 26.9 ms | 19.2 ms | 7.7 ms |

With upgraded JSON 2.19.8:

| Payload | JSON.generate | Oj.dump | JSON Savings |
|---------|---------------|---------|--------------|
| 1 MB | 2.8 ms | 4.0 ms | 1.2 ms |
| 4 MB | 10.2 ms | 12.5 ms | 2.3 ms |

## Ruby Version Matrix

All Ruby versions from 2.7 to 3.3 bundle JSON < 2.8.0:

| Ruby | Bundled JSON | Oj Benefit |
|------|--------------|------------|
| 3.0 | 2.5.1 | ~2 ms/MB |
| 3.1 | 2.6.1 | ~2 ms/MB |
| 3.2 | 2.6.3 | ~0.7 ms/MB |
| 3.3 | 2.7.2 | ~2 ms/MB |

However, JSON 2.19.8 (latest) supports Ruby 2.7+ and can be installed on any of these versions.

## Recommendations

### Option 1: Recommend JSON gem upgrade (Preferred)

Add to documentation that users can get ~2x faster JSON serialization by adding to their Gemfile:

```ruby
gem 'json', '>= 2.8'
```

**Pros:**
- No new dependency
- Better performance than Oj on modern JSON gem
- Future-proof (Ruby will eventually ship JSON 2.8+)

**Cons:**
- Requires user action
- Users may not read the docs

### Option 2: Add Oj as optional dependency

**Pros:**
- Helps users who don't upgrade JSON gem

**Cons:**
- Adds dependency
- Slower than upgraded JSON gem
- Two code paths to maintain

### Option 3: Require JSON >= 2.8 in gemspec

```ruby
s.add_dependency "json", ">= 2.8"
```

**Pros:**
- Automatic performance improvement for all users
- No conditional code

**Cons:**
- Forces gem upgrade (may conflict with other gems)

## Conclusion

The issue's hypothesis was valid for older JSON gem versions but is now outdated. The recommended approach is to document the JSON gem upgrade path for users who want optimal performance. This provides better performance than Oj without adding a dependency.

## Benchmark Scripts

The benchmark scripts used for this investigation are in the repository:
- `benchmark_json_serialization.rb` - Comprehensive benchmark across payload types
- `benchmark_multiversion.rb` - Cross-Ruby-version testing
- `benchmark_bundled_json.rb` - Tests with Ruby's bundled JSON
- `benchmark_json_versions.rb` - Historical JSON gem version comparison

## References

- Issue #3284: https://github.com/shakacode/react_on_rails/issues/3284
- JSON gem changelog: https://github.com/ruby/json/blob/master/CHANGES.md
- Oj gem: https://github.com/ohler55/oj
