# AbanoubGhadban and ihabadham Open Work Investigation (2026-06-01)

Research-only snapshot for open React on Rails issues and PRs authored by
AbanoubGhadban or ihabadham. This intentionally avoids changing contributor PR
branches. Where an issue already has an open PR, the recommendation is to use
this document as the `[INVESTIGATION]` sidecar rather than pushing code into the
existing work.

Last refreshed on 2026-06-02. Re-check mergeability, review comments, and CI
before acting on any recommendation below; PR conflicts and branch bases are
expected to drift quickly.

## Highest-Signal Sequence

1. Land the `RSCRoute ssr={false}` stack in order: rebase and merge
   [#3318](https://github.com/shakacode/react_on_rails/pull/3318), then retarget
   and merge [#3394](https://github.com/shakacode/react_on_rails/pull/3394).
   Keep [#3101](https://github.com/shakacode/react_on_rails/issues/3101) open
   until both PRs land.
2. Treat [#3211](https://github.com/shakacode/react_on_rails/issues/3211) as
   the most visible unowned release-quality bug. It has no open implementation
   PR and affects CSS first paint behind client boundaries.
3. Refresh [#3267](https://github.com/shakacode/react_on_rails/pull/3267) for
   [#2524](https://github.com/shakacode/react_on_rails/issues/2524). The async
   props helper APIs now exist on `main`; the remaining blocker is docs
   freshness/conflicts.
4. Do not merge [#2265](https://github.com/shakacode/react_on_rails/pull/2265)
   as-is. Split the useful async-props documentation into a docs-only PR under
   `docs/pro/`; keep runtime and test changes separate.
5. Close or park HTTPX-era leak experiments
   [#3287](https://github.com/shakacode/react_on_rails/issues/3287),
   [#3288](https://github.com/shakacode/react_on_rails/issues/3288),
   [#3289](https://github.com/shakacode/react_on_rails/issues/3289), and
   [#3290](https://github.com/shakacode/react_on_rails/issues/3290) after one
   current async-http disconnect smoke test tied to
   [#3295](https://github.com/shakacode/react_on_rails/issues/3295).
6. Keep PPR work
   [#3244](https://github.com/shakacode/react_on_rails/issues/3244) /
   [#3245](https://github.com/shakacode/react_on_rails/pull/3245) as research
   and positioning until stable RSC/Rspack/docs/testing gates are done.

## Existing PR Coverage

| Issue or PR                                                      | Coverage                                                                                                                       | Current state                                                                                                     | Recommended action                                                           |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [#3101](https://github.com/shakacode/react_on_rails/issues/3101) | [#3318](https://github.com/shakacode/react_on_rails/pull/3318), [#3394](https://github.com/shakacode/react_on_rails/pull/3394) | #3318 approved with green CI but conflicting in a Pro streaming test; #3394 approved and clean only on #3318 base | Rebase #3318 first, merge, then retarget/rebase #3394 onto `main`            |
| [#2524](https://github.com/shakacode/react_on_rails/issues/2524) | [#3267](https://github.com/shakacode/react_on_rails/pull/3267)                                                                 | Approved but conflicting; helper implementation now exists on `main`                                              | Rebase and de-duplicate docs, then merge if still net-new                    |
| [#3106](https://github.com/shakacode/react_on_rails/issues/3106) | [#3215](https://github.com/shakacode/react_on_rails/pull/3215)                                                                 | Approved but stale/conflicting                                                                                    | Park unless needed for demo/prospect; rebase after #3318/#3394               |
| [#3209](https://github.com/shakacode/react_on_rails/issues/3209) | [#3210](https://github.com/shakacode/react_on_rails/pull/3210)                                                                 | Draft, conflicting, review required                                                                               | Rebase and undraft only if cleanup is in current release scope               |
| [#3244](https://github.com/shakacode/react_on_rails/issues/3244) | [#3245](https://github.com/shakacode/react_on_rails/pull/3245)                                                                 | Draft, conflicting, failing lint/markdown checks                                                                  | Preserve as research; rewrite acceptance around PPR + RSC composition        |
| [#3313](https://github.com/shakacode/react_on_rails/issues/3313) | [#3349](https://github.com/shakacode/react_on_rails/pull/3349)                                                                 | Approved, but conclusion is stale because `main` now requires Ruby >= 3.3                                         | Refresh the decision record before merge                                     |
| [#2265](https://github.com/shakacode/react_on_rails/pull/2265)   | Async props docs work                                                                                                          | Approved but conflicting; mixes docs, runtime, node-renderer, and Pro changes                                     | Split into docs-only work under `docs/pro/` plus separate implementation PRs |

## Open Issues Without a Direct PR

| Issue                                                                                                                                                                                                                                                                                                                                    | Recommendation                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [#3211](https://github.com/shakacode/react_on_rails/issues/3211)                                                                                                                                                                                                                                                                         | Create a focused implementation PR for CSS manifest/preload behavior. Include a dummy-app regression with CSS imported behind a client boundary.                                            |
| [#3212](https://github.com/shakacode/react_on_rails/issues/3212)                                                                                                                                                                                                                                                                         | Do not block release unless a clean install still reproduces. Prefer plugin hardening or the monorepo RSC package move in [#3497](https://github.com/shakacode/react_on_rails/issues/3497). |
| [#3295](https://github.com/shakacode/react_on_rails/issues/3295)                                                                                                                                                                                                                                                                         | Validate current async-http transport with one disconnect smoke test. Close as superseded/fixed if it passes.                                                                               |
| [#3300](https://github.com/shakacode/react_on_rails/issues/3300)                                                                                                                                                                                                                                                                         | Rewrite into a concrete test-gap matrix before implementation.                                                                                                                              |
| [#3100](https://github.com/shakacode/react_on_rails/issues/3100)                                                                                                                                                                                                                                                                         | Defer unless i18n/auth server-component ergonomics become a launch blocker.                                                                                                                 |
| [#3202](https://github.com/shakacode/react_on_rails/issues/3202), [#3203](https://github.com/shakacode/react_on_rails/issues/3203)                                                                                                                                                                                                       | Close or demote if `upcoming-v16.3.0` is no longer the release line.                                                                                                                        |
| [#3470](https://github.com/shakacode/react_on_rails/issues/3470)                                                                                                                                                                                                                                                                         | Keep in docs wave. Follow #3267 so async-props wording stays consistent.                                                                                                                    |
| [#3386](https://github.com/shakacode/react_on_rails/issues/3386)                                                                                                                                                                                                                                                                         | Defer unless current tests hide a real async-http bug.                                                                                                                                      |
| [#3107](https://github.com/shakacode/react_on_rails/issues/3107)                                                                                                                                                                                                                                                                         | Mostly resolved by shared `script/lib/git-diff-base`; convert to a narrow lefthook follow-up or close with a follow-up.                                                                     |
| [#2552](https://github.com/shakacode/react_on_rails/issues/2552)                                                                                                                                                                                                                                                                         | Keep as deferred RFC. Prefer a low-risk wording/log clarity PR before any broad filename rename.                                                                                            |
| [#2182](https://github.com/shakacode/react_on_rails/issues/2182)                                                                                                                                                                                                                                                                         | Close as superseded or keep only as historical pointer to #3244/#3245/#3255.                                                                                                                |
| [#2169](https://github.com/shakacode/react_on_rails/issues/2169)                                                                                                                                                                                                                                                                         | Park until release-critical runtime work is stable.                                                                                                                                         |
| [#3282](https://github.com/shakacode/react_on_rails/issues/3282), [#3284](https://github.com/shakacode/react_on_rails/issues/3284), [#3285](https://github.com/shakacode/react_on_rails/issues/3285), [#3291](https://github.com/shakacode/react_on_rails/issues/3291), [#3292](https://github.com/shakacode/react_on_rails/issues/3292) | Keep as research experiments only; do not let them displace launch blockers.                                                                                                                |
| [#3287](https://github.com/shakacode/react_on_rails/issues/3287), [#3288](https://github.com/shakacode/react_on_rails/issues/3288), [#3289](https://github.com/shakacode/react_on_rails/issues/3289), [#3290](https://github.com/shakacode/react_on_rails/issues/3290)                                                                   | Close as superseded after one current async-http smoke check.                                                                                                                               |

## Comment Drafts

Post these drafts on the referenced PRs/issues before acting on their
recommendations, especially where contributor branches would be rebased,
retargeted, closed, or split.

### #3318

```md
Readiness note: this is still the first PR to land for #3101. It is approved and the checks look good, but GitHub currently reports it as conflicting against `main`.

Recommended next step: rebase/resolve #3318 first, then rerun the focused Pro package tests and the `rsc_route_ssr_false` E2E. The current visible conflict is in `packages/react-on-rails-pro/tests/streamServerRenderedReactComponent.test.jsx`, where current `main` added CSP nonce coverage for streamed RSC rendering.

While the branch is open, consider the one test-quality cleanup called out in review: replace the bare `catch {}` in `deferredRouteSsr.test.tsx` with an assertion-friendly pattern or a short comment explaining the intentionally ignored error.

After this lands, #3394 can be retargeted/rebased onto `main`.
```

### #3394

```md
Stacking note: this PR is approved and clean against `ihabadham/feature/rsc-route-ssr-false`, so it should wait for #3318.

Recommended sequence:

1. Land #3318 after resolving its `main` conflicts.
2. Retarget/rebase this PR onto `main`.
3. Rerun the Pro package/generator/E2E checks because this PR touches generated packs, `ClientSideRenderer`, and the Pro dummy app.
4. Then merge this as the default-provider follow-up that completes #3101.
```

### #3267

```md
Docs dependency update: the async-props helpers documented here now appear to exist on `origin/main` (`stream_react_component_with_async_props`, `rsc_payload_react_component_with_async_props`, and `getReactOnRailsAsyncProp`), so this no longer looks blocked on missing implementation.

The remaining blocker is freshness: GitHub reports conflicts, and current `main` has since changed several of the same RSC migration/data-fetching docs. Recommended next step is a rebase/de-dup pass against current `main`, then merge if the PR still adds net-new guidance for #2524.
```

### #3300

```md
Suggested next step: rewrite this issue before implementation starts. After #3320, the useful scope is not "add more tests" broadly, but a concrete gap matrix: async-props happy path, malformed length-prefixed chunks, truncated frames, renderer error metadata, client abort/disconnect, 410 retry/reupload, and any skipped specs. Once that matrix is agreed, a focused test PR can implement only the missing cases.
```

### #3295 and #3287-#3290

```md
Given #3320 has now moved renderer transport off HTTPX, I think the next useful step is not the original HTTPX cancellation fix. Validate the current async-http stack with a focused client-disconnect regression: abort an RSC/async-props stream mid-response, then assert later RSC routes still return quickly without pool exhaustion. If that passes, #3295 can close as superseded/fixed by #3320, and #3287-#3290 can close rather than continuing old HTTPX experiments.
```

### #3313 / #3349

```md
Triage update: #3349 appears to deliver the requested spike, but the decision record should be refreshed before merge. The PR currently recommends keeping the scanner until React on Rails drops Ruby 3.0-3.2; current `main` now has `required_ruby_version = ">= 3.3.0"` for both OSS and Pro gems.

That changes the central tradeoff: Prism is no longer primarily a runtime dependency cost for supported CRuby versions. Suggested next step: update the spike conclusion to either recommend a concrete Prism implementation follow-up, or explicitly explain why the scanner should remain despite the Ruby floor now being 3.3+.
```

### #3107

```md
Current-state note: most of this observation has already been addressed. `script/ci-changes-detector` and `script/check-docs-sidebar` now share `script/lib/git-diff-base`; `bin/lefthook/get-changed-files` is the remaining script still using a local `origin/main` check.

Recommendation: either close this as mostly resolved and file a smaller follow-up for lefthook, or convert this issue to that narrow task. Acceptance criteria would be: branch-mode lefthook changed-file detection either uses the shared helper or documents why it intentionally stays simpler; missing/stale `origin/main` behavior is covered; macOS Bash compatibility is preserved.
```

### #2552

```md
Recommendation: keep this as a deferred RFC rather than starting a full rename now. Current `main` still has the `*WebpackConfig.js` names across generator templates, docs, specs, and Pro/RSC setup code, so a rename remains a broad breaking/migration change.

A low-risk alternative would be a smaller clarity PR: add generated-file comments and log wording that explain these configs are bundler-agnostic despite the historical filename. Full bundler-neutral renames should wait for an explicit major-version migration decision.
```

## Suggested Verification If Work Moves Past Research

- `bundle exec rspec` focused Pro helper/request specs for async props and
  disconnect behavior.
- Pro package tests around `RSCRoute`, `RSCProvider`, and generated packs after
  #3318/#3394 rebases.
- Docs link/sidebar checks after #3267 or #2265 split work.
- A current async-http abort smoke test before closing #3295 and the superseded
  HTTPX experiment issues.
