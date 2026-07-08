# Async Props Prerender Cache Security Decision

Date: 2026-07-07

## Scope

This note records the release-note and GitHub Security Advisory decision for the React on Rails Pro async-props
prerender-cache isolation fix in PR 4376 / commit `cdcba5438dd559a5e54029b1b6931b8ddc6d7beb`.

## Live Evidence

- `git tag --contains cdcba5438` returned no tags.
- `git merge-base --is-ancestor cdcba5438 v17.0.0.rc.6` exited 1, so the latest visible 17.0.0 RC does not contain the fix.
- `git merge-base --is-ancestor cdcba5438 origin/main` exited 0, so `origin/main` contains the fix.
- `gh release list --repo shakacode/react_on_rails --limit 20` showed visible releases through `v17.0.0.rc.6`.
- `gh api -H 'Accept: application/vnd.github+json' '/repos/shakacode/react_on_rails/security-advisories' --paginate` returned `[]`.
- `gh api -H 'Accept: application/vnd.github+json' '/repos/shakacode/react_on_rails/security-advisories?state=open' --paginate` returned `[]`.
- `git tag --contains 814c19c50` showed the async-props feature in `v16.7.0.rc.0` through `v16.7.0.rc.3` and
  `v17.0.0.rc.0` through `v17.0.0.rc.6`.
- `git merge-base --is-ancestor 814c19c50 v16.6.0` exited 1, so the last stable `16.x` release did not contain the
  async-props feature.

## Decision

Do not request or publish a GHSA/CVE for this lane based on current evidence. The affected async-props feature and the
fix are both in the prerelease train only, and no stable release tag contains the affected feature. If later evidence
shows a stable release or supported customer build contains the affected behavior, reopen advisory triage and use the
private GitHub advisory path described in `SECURITY.md`.

## Public Release-Note Framing

Use this public-safe framing:

> Pro prerender stream caching now bypasses renders that use async props, keeping per-request async stream output
> isolated from prerender-cache hits. Prerelease builds `v16.7.0.rc.0` through `v16.7.0.rc.3` and `v17.0.0.rc.0`
> through `v17.0.0.rc.6` included async-props streaming before this fix; no stable tag contains the affected
> async-props feature. Upgrade to a 17.0.0 RC or final release that includes this fix before enabling global
> prerender caching on async-props streaming pages.

Do not include reproduction steps, cache-key internals, or exploit payload details in public release notes.
