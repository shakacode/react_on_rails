# Issue #3258 — RSC Migration Parser Helper Clarity Cleanup

**Status:** Design approved; implementation in review
**Author:** Justin Gordon (drafted with Claude Code)
**Date:** 2026-05-21
**Related PR:** #3219 (`codex/fix-rsc-client-reference-scope`)
**Branch strategy:** Stacked follow-up PR on top of `codex/fix-rsc-client-reference-scope` so review of the behavioral fix in #3219 stays isolated from this clarity cleanup.

## Background

PR #3219 (`fix: scope RSC client reference discovery`) ships a behavioral fix
that scopes `RSCWebpackPlugin#clientReferences` to the Shakapacker
`config.source_path` for both new installs and existing webpack configs. The PR
introduces a sizeable migration path in
`react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb` that detects an
existing `RSCWebpackPlugin(...)` call, parses its options block with a
lightweight JS scanner, and either rewrites the options or warns when a rewrite
is unsafe.

The cloud reviews on #3219 flagged three non-blocking clarity items. They were
intentionally deferred from #3219 to keep that PR focused on behavior. Issue
\#3258 tracks them.

This spec covers only those three items. No behavior changes.

## In Scope

1. Rename `rsc_plugin_without_client_references?` so the per-section
   ("any one of the sections lacks `clientReferences`") semantics are explicit.
2. Tighten the scanner-supported-surface documentation around regex literals
   with curly braces. No parser changes.
3. Remove the duplicate defensive guards at the top of
   `add_rsc_client_references_setup`, and document its precondition.

All three changes are confined to `client_references.rb` and its existing spec file.

## Out of Scope

- Behavioral changes to the migration logic.
- Expanding the JS scanner to handle regex-literal brace quantifiers
  (e.g. `/a{2}/`). The generated configs never produce such regexes, and
  existing-config rewrites already emit a warning rather than guess when the
  scanner cannot parse a block. Revisit only if a future RSC plugin option
  requires it.
- Touching any other PR #3219 review feedback. Each remaining cloud-review item
  either has its own follow-up issue or was already addressed in #3219.

## Item 1 — Rename `rsc_plugin_without_client_references?`

### Current state

```ruby
def rsc_plugin_without_client_references?(content, is_server:)
  rsc_plugin_option_sections(content, is_server: is_server).any? do |section|
    !rsc_plugin_options_without_comments(section.fetch(:body)).match?(/\bclientReferences\s*:/)
  end
end
```

The implementation uses `.any?`, but the method name suggests an all-or-nothing
check ("the plugin has no clientReferences"). When two plugin instances share
the same `isServer` value and one already has `clientReferences` while the
other does not, the method correctly returns `true` and the rewrite proceeds —
but a reader who only inspects the name would expect that case to return
`false`.

### New name

`any_rsc_plugin_section_without_client_references?`

- Keeps the existing predicate suffix (`?`).
- Adds the `any_` prefix that mirrors the `.any?` in the body.
- Replaces `plugin` with `plugin_section` to match `rsc_plugin_option_sections`
  (the data the method iterates over).

### Affected sites

Only two call sites exist in `client_references.rb`:

```text
react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb:141
react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb:163
```

The method is private to the generator class; no spec asserts on the method
name directly. A repo-wide grep confirms no other production or test code
references the symbol.

### Acceptance

- `bundle exec rubocop react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb`
  passes.
- `bundle exec rspec react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb`
  passes unchanged.

## Item 2 — Document scanner-supported surface for regex-literal braces

### Current state

`rsc_plugin_options_without_comments` (around line 671 on the PR branch) carries
a comment noting that regex literals like `/a{2}/` are outside the scanner's
supported surface because brace quantifiers can confuse
`matching_js_closing_brace`'s depth counter.

`matching_js_closing_brace` itself (the helper that actually does the brace
tracking) carries no such note. A reader who lands on that helper directly —
e.g. via a stack trace from a future bug — has no inline indication that regex
literals are an unsupported input class.

### Change

Add a brief comment block above `matching_js_closing_brace` that lists what it
supports (strings, line and block comments) and what it does not (regex
literals — specifically brace quantifiers like `/a{2}/` and character classes
like `/[{]/`). Cross-reference `rsc_plugin_options_without_comments` so readers
can see why the limitation is acceptable in the current call graph.

Tighten the existing comment on `rsc_plugin_options_without_comments` to use
the same phrasing for "unsupported constructs," so both comments read as one
documented contract instead of two slightly different warnings.

The warning text emitted by `warn_unparseable_rsc_plugin_sections` already
explains the user-facing failure mode (`"most often a regex literal with an
unmatched '{' or '}', e.g. '/\{/' or '/[{]/'"`), so no warning-message change
is needed.

### Acceptance

- No code changes outside of comments.
- `bundle exec rubocop` passes.

## Item 3 — Remove duplicate defensive guards in `add_rsc_client_references_setup`

### Current state

```ruby
def add_rsc_client_references_setup(config_path, content, existing_imports_content, is_server:)
  return false if scoped_rsc_client_references_defined?(content)
  return false if rsc_client_references_defined?(content)

  replace_rsc_client_references_setup_anchor(config_path, content, is_server: is_server) do |anchor|
    [
      anchor,
      shakapacker_config_import_statement(existing_imports_content),
      path_resolve_import_statement(existing_imports_content),
      "",
      rsc_client_references_js
    ].compact.join("\n")
  end
end
```

The sole caller, `ensure_rsc_client_references_setup`, already performs both
checks before invoking this method:

```ruby
def ensure_rsc_client_references_setup(config_path, content, is_server:)
  return true if scoped_rsc_client_references_defined?(content)

  if rsc_client_references_defined?(content)
    warn_unscoped_rsc_client_references_helper(config_path)
    return false
  end
  ...
  add_rsc_client_references_setup(config_path, content, existing_imports_content, is_server: is_server)
  ...
end
```

The duplicated guards inside `add_rsc_client_references_setup` are unreachable
in the current call graph. CLAUDE.md guidance: "Don't add error handling,
fallbacks, or validation for scenarios that can't happen. Trust internal code
and framework guarantees."

### Change

- Remove the two `return if ...` guards.
- Replace the existing leading comment with one that names the precondition:
  must only be called via `ensure_rsc_client_references_setup`, which has
  already verified that no `rscClientReferences` declaration (scoped or
  otherwise) exists at module scope and that the import anchor is present.

### Acceptance

- `bundle exec rspec react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb`
  passes — existing specs already exercise the `ensure_*` path on every code
  path that ends up calling `add_*`.
- `bundle exec rubocop` passes.
- Manual code reading: no other call site to `add_rsc_client_references_setup`
  appears in the repo (verified via `grep`).

## Risk Assessment

- **Item 1:** Pure rename of a private method with a single call site. Risk:
  near zero. Worst case: a missed reference produces an immediate
  `NoMethodError` caught by the existing spec suite.
- **Item 2:** Comments only. Zero runtime risk.
- **Item 3:** Removes dead code. The risk is that a future caller could be
  added without re-applying the guards. Mitigated by the precondition comment;
  the helper is private and lives in the same file as its caller, so a future
  contributor sees both within the same edit window.

## Test Plan

- `bundle exec rspec react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb`
- `bundle exec rubocop react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb`
- Manual `grep` for the old method name across the repo to confirm zero stale
  references after the rename.

## Out of Scope (Reiterated)

No changes to:

- `react_on_rails/lib/generators/react_on_rails/templates/**`
- Any documentation file outside this design spec.
- The behavior or wording of `GeneratorMessages` warnings.

## Follow-ups

None planned. If a future RSC plugin option introduces regex literals with
brace quantifiers, file a new issue to expand `matching_js_closing_brace` (or
adopt a real JS parser); the warning emitted today gives users a clear manual
remediation in the meantime.
