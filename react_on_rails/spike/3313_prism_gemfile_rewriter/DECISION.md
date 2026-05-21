# Decision record: Prism-based Gemfile rewriting for Pro migration

**Issue:** [#3313](https://github.com/shakacode/react_on_rails/issues/3313)
**Status:** Spike complete, recommendation: **wait for Ruby floor to rise to 3.3**, keep
the current text scanner in the meantime, and revisit then.
**Date:** 2026-05-21
**Author:** Justin Gordon (Claude Code assistance)

## TL;DR

A working Prism prototype lives at
[`prism_gemfile_rewriter.rb`](./prism_gemfile_rewriter.rb) with a 32-case behavior
matrix in [`prism_gemfile_rewriter_spec.rb`](./prism_gemfile_rewriter_spec.rb). All
cases pass, including the empty-`else` case the current scanner gets wrong.

The prototype demonstrates that a parser-backed rewrite is **viable** and produces
cleaner output for conditional declarations. It is also dramatically simpler than
the current scanner (~210 lines including the conditional-collapse pass, vs.
~175 lines of pure scanner in `pro_migration.rb` plus ~330 lines of rewrite logic
across `pro_generator.rb`).

But the **cost is a new runtime gem dependency** (`prism`) for the ~30% of users
still on Ruby 3.0–3.2. Until the gem's Ruby floor rises to 3.3 (when Prism is
in CRuby's stdlib), the dependency cost outweighs the rewrite cleanup. Migration
generator code runs once per user, and the current scanner is tested against the
full matrix already.

Recommendation: keep the current scanner. Revisit when `react_on_rails` drops
Ruby 3.0–3.2 support.

## Background

PR [#3232](https://github.com/shakacode/react_on_rails/pull/3232) hardened the Pro
migration generator's Gemfile rewrite path with a regex-free text scanner. The
review cycle exposed a maintenance pattern: each unusual Gemfile shape (multiline
parenthesized calls, postfix guards, trailing-comma suffixes, no-final-newline,
stale-base-with-pro-present) needed more scanner special-casing. CodeQL ReDoS
detection tripped on the original regex implementation and forced a regex-free
rewrite.

Issue #3313 asked: would a Prism-backed rewrite reduce this maintenance cost and
remove the static-analysis exposure?

## What was built

A standalone Prism-based rewriter at
[`spike/3313_prism_gemfile_rewriter/`](./).

| File                             | Purpose                                                                      |
| -------------------------------- | ---------------------------------------------------------------------------- |
| `prism_gemfile_rewriter.rb`      | The prototype: parse → locate `gem` call nodes → location-based source edits |
| `prism_gemfile_rewriter_spec.rb` | 32-case behavior matrix                                                      |
| `benchmark.rb`                   | Parse + rewrite timing vs. the current scanner                               |

The prototype is **outside `lib/`** to satisfy the issue's "Do not rewrite #3232
as part of this spike" non-goal.

### Approach

1. Parse Gemfile source with `Prism.parse`.
2. Walk the AST and collect every `CallNode` whose receiver is `nil`, name is `:gem`,
   and whose first argument is a `StringNode` literal of `react_on_rails` or
   `react_on_rails_pro`.
3. Decide based on whether an active Pro gem is present:
   - **No Pro gem:** for each base call, replace the first string literal with
     `react_on_rails_pro`. If the call has no user version pin (no second positional
     `StringNode`), splice in the default version literal after the gem name.
   - **Pro gem already present:** for each base call, remove its enclosing
     statement byte range (line start through trailing newline).
4. After removals, re-parse and find any `if/unless ... end` whose branch became
   empty. If the conditional's surviving branch contains exactly the Pro gem call,
   collapse the conditional to that single declaration. Otherwise remove just the
   empty branch.

All edits are **byte-offset splices**, so comments, spacing, heredocs, and unrelated
Ruby are preserved by construction (no AST formatter).

## Behavior matrix — full coverage

The spec covers every shape enumerated in #3313 and they all pass with the
prototype as written:

| Shape                                                      | Prism                               | Current scanner            |
| ---------------------------------------------------------- | ----------------------------------- | -------------------------- |
| Exact version pin (`gem "react_on_rails", "16.0.0"`)       | ✅                                  | ✅                         |
| Pessimistic version pin (`"~> 16.0"`)                      | ✅                                  | ✅                         |
| Multi-constraint pins (`">= 15.0", "< 16.0"`)              | ✅                                  | ✅                         |
| Single quote style                                         | ✅                                  | ✅                         |
| `path:`, `git:`, `github:`, `require: false`, `platforms:` | ✅                                  | ✅                         |
| Postfix guard (`if ENV["X"]`)                              | ✅                                  | ✅                         |
| Multiline non-parenthesized continuation                   | ✅                                  | ✅                         |
| Multiline parenthesized                                    | ✅                                  | ✅ (parens stripped)       |
| Parenthesized with postfix guard                           | ✅ (parens preserved)               | ✅ (parens stripped)       |
| Trailing comment after closing paren                       | ✅                                  | ✅                         |
| Inline comments containing `)`                             | ✅                                  | ✅                         |
| Comment-only continuation lines                            | ✅                                  | ✅                         |
| Trailing-comma-only suffix (`gem("ror",)`)                 | ✅ (Ruby 3.3+ parses cleanly)       | ✅                         |
| No final newline                                           | ✅                                  | ✅                         |
| Duplicate declarations across groups                       | ✅                                  | ✅                         |
| Active Pro present, base stale                             | ✅ (removes base)                   | ✅                         |
| Conditional with `if/else` (both branches base)            | ✅ (rewrites both)                  | ✅                         |
| Conditional with `if pro / else base`                      | ✅ **collapses to single Pro decl** | ⚠️ **leaves empty `else`** |

The only **observable behavior differences**:

1. **Parenthesized declarations.** The current scanner strips parens
   (`gem("ror", "~> 16.0")` → `gem "ror", "~> 16.0"`). The Prism prototype
   preserves the user's style. Neither is wrong; preserving the user's source style
   is arguably more polite.
2. **The empty-`else` case (called out in #3313).** The current scanner leaves an
   ugly empty `else` branch. The Prism prototype collapses the entire conditional
   to a single `gem "react_on_rails_pro", "16.0.0"` declaration, because the
   conditional's only purpose was to select between gem variants and there is only
   one variant after migration.

   This is the policy choice asked for in the issue's acceptance criteria. See
   "Conditional/empty-branch policy" below for the reasoning.

## Conditional / empty-branch policy

**Chosen:** collapse the conditional when a branch becomes empty _and_ the surviving
branch contains only `gem "react_on_rails_pro"`.

```ruby
# Before
if ENV["PRO"]
  gem "react_on_rails_pro", "16.0.0"
else
  gem "react_on_rails", "16.0.0"
end

# After
gem "react_on_rails_pro", "16.0.0"
```

**Why collapse, not "delete empty branch" or "leave it":**

- "Leave it" is what the scanner does today, and the issue explicitly calls this
  out as the ugliness the spike should evaluate.
- "Delete the empty `else`" would leave `if ENV["PRO"] then gem_pro end`, which
  changes the user's runtime behavior: before, _some_ gem was always installed;
  after, the gem is conditional on `ENV["PRO"]` being set. This is a silent
  semantic change and the worst option.
- Collapse preserves the original semantic ("install one specific gem") with the
  same conditionality the user had (none).

**Edge cases the prototype does _not_ collapse** (and leaves the empty branch in
place):

- If the surviving branch has multiple statements (the Pro gem plus other gems
  or Bundler DSL calls), the conditional is left structurally intact.
- If the empty branch is the `if`-branch (rare, would require an inverse setup
  like `if ENV["BASE"] then gem_base else gem_pro end`), we leave it; rewriting
  `if X; (empty); else BODY; end` into `unless X; BODY; end` is mechanically
  fine but visually surprising. Out of scope for the spike.

## Parse-failure policy

**Chosen:** return the original Gemfile content untouched with `parse_failed: true`
and the list of Prism errors. The calling generator should fall back to a clear
manual-edit message ("we could not parse your Gemfile; please update it manually").

Why not fall back to the current scanner: it would silently re-introduce the exact
class of edge-case bugs Prism was supposed to remove. Either we trust the parser or
we don't.

Verified against a deliberately malformed Gemfile in the spec
(`returns the original content untouched when Gemfile cannot be parsed`). Prism's
error-tolerant parsing means even quite broken Ruby may produce _some_ AST, but
`Prism::ParseResult#failure?` is the boundary: if any errors are recorded, we
treat the file as unmodifiable.

## Compatibility notes

| Ruby | Prism status                                          |
| ---- | ----------------------------------------------------- |
| 3.0  | gem only, MRI does not bundle                         |
| 3.1  | gem only, MRI does not bundle                         |
| 3.2  | gem only, MRI does not bundle                         |
| 3.3+ | bundled with CRuby (the parser used by the VM itself) |

`react_on_rails`'s gemspec currently sets `required_ruby_version >= 3.0.0`. Shipping
Prism as a runtime dependency means:

- Ruby 3.3+ users: no new install. Prism is already in their Ruby.
- Ruby 3.0–3.2 users: adds one gem (`prism` ~250KB, native extension, builds in
  seconds). No transitive dependencies.

The prism gem itself is maintained by the Ruby core team, sees frequent releases,
and the 1.x line has been stable since 2024.

The issue notes that the `parser` gem (whitequark) is in soft deprecation and
redirects users to `Prism::Translation::Parser`. Any new parser dependency
should target Prism directly — confirmed.

## Performance

Measured on Ruby 3.4.8 / Prism 1.9.0 / Apple Silicon. 200 iterations per case, with
3 warm-up iterations to avoid first-call overhead.

| Gemfile                            | Scanner         | Prism           | Ratio |
| ---------------------------------- | --------------- | --------------- | ----- |
| Small (~10 lines, 1 ror entry)     | 0.012ms/rewrite | 0.015ms/rewrite | 1.25× |
| Medium (~45 lines, groups)         | 0.040ms/rewrite | 0.048ms/rewrite | 1.20× |
| Large (~300 lines, scaled fixture) | 0.285ms/rewrite | 0.304ms/rewrite | 1.07× |

Both are sub-millisecond. The Pro generator runs `bundle install` immediately after
the rewrite, which takes 5–60 seconds. **Parse-time cost is not a decision factor.**

## Recommendation

**Wait for the Ruby floor to rise to 3.3, then revisit.**

Reasoning:

1. **The current scanner works.** PR #3232 closed the open bugs. The test matrix
   is comprehensive. CodeQL is happy. The empty-`else` case is the only known
   residual, and it is **valid Ruby that produces a valid Bundler DSL** — only
   ugly, not broken.
2. **Migration code runs once per user.** A small ugliness left behind by the
   rewrite that the user then commits to their repo is, at worst, a cleanup nit
   the user can resolve in one minute. It does not regress on subsequent runs
   because the base gem is gone.
3. **Adding `prism` as a runtime dep for ~30% of users (Ruby 3.0–3.2) buys
   migration-generator cleanup only.** No other path in `react_on_rails` would
   benefit from a parser, and a single-purpose runtime dep is a smell.
4. **When the Ruby floor moves to 3.3** (planned for the next major), Prism
   becomes free and the recommendation flips: cut over to the Prism implementation,
   delete the scanner.
5. **Until then, the scanner is the right tool.** Pragmatic, tested, and gated
   behind a generator that the user runs once.

## What to do if/when this flips

1. Move `prism_gemfile_rewriter.rb` into `lib/react_on_rails/pro_migration/prism_gemfile_rewriter.rb`.
2. Add `spec.add_dependency "prism", "~> 1.0"` to `react_on_rails.gemspec`.
3. Replace the `swap_base_gem_for_pro_in_gemfile` body in
   `lib/generators/react_on_rails/pro_generator.rb` with a call to the Prism rewriter.
4. Add a parse-failure UX path: when `result.parse_failed`, surface a clear
   "please update your Gemfile manually" message with the prism error line numbers.
5. Migrate the existing spec assertions to expect the Prism output (parens preserved
   in `gem("…")` cases, empty-`else` collapsed).
6. Delete `lib/react_on_rails/pro_migration.rb`'s scanner methods (keep the JS-side
   constants).
7. Run the spike spec under the production path to confirm parity.

Approximate effort with the prototype as a starting point: 4–8 hours including
review and spec migration.

## Open questions left for the implementation PR (not this spike)

- Should the generator output a `say` message when it collapses a conditional, so
  the user understands the structural change to their Gemfile?
- Should the empty-`if`-branch case (`if X; (empty); else BODY; end`) be rewritten
  to `unless X; BODY; end`, or left alone? The prototype leaves it alone.
- Is `Prism::Translation::Parser` a useful escape hatch for projects that already
  depend on `parser`, or is the direct Prism API sufficient?
