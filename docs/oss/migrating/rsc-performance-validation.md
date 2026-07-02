# RSC Performance Validation Playbook

Use this playbook when an RSC migration is intended to improve page performance. It defines the
evidence package reviewers need before treating an RSC conversion as a performance win.

> **Part 9 of the [RSC Migration Series](migrating-to-rsc.md)** | Previous:
> [Flight Payload Optimization](rsc-flight-payload.md) | Next:
> [Mostly Static RSC Shell With a Tiny Sidecar](rsc-static-shell-sidecar.md)

## Start With a Local Control and Experiment

The cleanest merge signal is usually a local A/B comparison:

- **Control:** current `origin/main`, or the explicit baseline branch the app already uses in
  production.
- **Experiment:** the PR branch or candidate branch.
- **Machine:** same developer machine, same browser version, same CPU/network throttling, same sample
  order.
- **Builds:** comparable production-like builds. Do not compare a development server with compiled
  production assets.
- **Environment:** same data snapshot, Rails cache state, browser cache policy, image/CDN setup,
  asset host, feature flags, secrets, and locale/device assumptions.
- **Smoke test first:** open every control and experiment URL before measuring. Confirm the page
  returns the expected status, real images and fonts load, and required user-visible content is
  present.

Review-app, staging, production PageSpeed, and production Lighthouse runs are useful context, but
they are not automatically a clean A/B. CDN, hosting, cache warmth, data, image signatures, and deploy
topology can differ enough to explain the result.

## Compare Against the Real Incumbent Path

RSC should be compared against the path users actually have today. If the existing page uses
[`cached_react_component` or `cached_react_component_hash`](../building-features/caching.md#level-2-fragment-caching)
with React on Rails Pro prerender caching, include a warm cached SSR baseline. A static page that is
already served from a warm SSR fragment cache can be very hard to beat on TTFB, FCP, or LCP, even
when RSC reduces hydration work and JavaScript bytes.

Use the matrix in
[Benchmarking RSC Against Warm SSR Caches](../core-concepts/performance-benchmarks.md#benchmarking-rsc-against-warm-ssr-caches)
to label cold uncached SSR, warm cached SSR, RSC cold, and RSC warm runs. The public tracker for that
tradeoff is [#4294](https://github.com/shakacode/react_on_rails/issues/4294).

## Pair Visual Regression With Performance

Performance evidence is incomplete without visual evidence. A page is not faster in a useful sense if
it is missing visible UI, fonts, images, layout wrappers, search bars, or mobile navigation behavior.

For every changed page and viewport:

- Run visual checks in the same validation loop as performance checks.
- Report diff pixels and diff percent, not only "looks fine".
- Block unaccepted visual changes. Treat them as regressions unless the UI change was explicitly
  reviewed and accepted.
- Confirm screenshots include real page assets before using them as evidence.
- Recheck keyboard, focus, and responsive states when the migration changes hydration or global
  JavaScript loading.

This also protects performance interpretation. A lower Total Blocking Time can be real while LCP gets
worse because CSS, fonts, or the LCP image moved later in the critical path.

## Keep the Package Stack Stable

Final merge evidence should use installable packages:

- Published packages, canary packages, or release-candidate packages are valid final evidence.
- Framework `main` source checkouts and local package tarballs are diagnostic only unless the tested
  package has been published and remeasured.
- If a local tarball is useful during diagnosis, record its package name, version, source commit, and
  shasum.
- If a main-tip diagnostic improves performance, publish or use a canary/RC and rerun visual plus
  performance before depending on it.
- If a diagnostic stack improves performance but fails visual parity, it is not a ship candidate.

Keep one variable per run. Do not combine an app conversion, package bump, framework SHA, bundler
configuration change, and static-shell sidecar rewrite in one measurement if the result needs to
guide implementation.

## Archive and Parse Benchmark Output

Each run should leave durable artifacts. Name archives so a future reader can identify the stack,
baseline, candidate, date, pages, and viewport set without opening the report.

Record:

- Archive path or published artifact URL.
- Tool version and configuration.
- Control and experiment URLs.
- Control and experiment SHAs.
- Package versions and package SHAs or shasums where relevant.
- Pages and viewports tested.
- Environment caveats, especially local-vs-production differences.

Parse JSON or equivalent machine-readable artifacts. Do not rely on terminal scrollback or a single
summary screenshot.

For ShakaPerf runs based on the HiChee lesson:

- Run visual plus performance for every changed page and viewport.
- Use Lighthouse `throttlingMethod: 'devtools'` for this workflow.
- Prefer sequential sampling on one developer machine unless the benchmark setup was designed for
  parallel execution.
- Save both the full report and the self-contained report when available.

The methodology matters more than the tool. ShakaPerf is the known ShakaCode workflow; equivalent
tooling is fine when it produces the same control/experiment, visual, performance, and archived
evidence.

## Metrics Checklist

Include this checklist in the PR description or benchmark comment:

| Evidence         | Required detail                                                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| URLs             | Control URL and experiment URL                                                                                                  |
| SHAs             | Control SHA and experiment SHA                                                                                                  |
| Package stack    | React on Rails, React on Rails Pro, `react-on-rails`, `react-on-rails-pro`, `react-on-rails-rsc`, and tarball shasums when used |
| Pages/viewports  | Every changed page and desktop/mobile viewport that matters                                                                     |
| Visual diff      | Diff pixels and percent for each page/viewport                                                                                  |
| Lighthouse score | Score for control and experiment, plus win/regression/no material change                                                        |
| FCP              | Control, experiment, delta, verdict                                                                                             |
| Speed Index      | Control, experiment, delta, verdict                                                                                             |
| LCP              | Control, experiment, delta, verdict                                                                                             |
| TBT              | Control, experiment, delta, verdict                                                                                             |
| Total downloads  | Control, experiment, delta, verdict                                                                                             |
| JavaScript bytes | Control, experiment, delta, verdict                                                                                             |
| Caveats          | Local-vs-production, cache, CDN, image, data, throttling, sample-size, or visual caveats                                        |

Use honest verdicts. It is valid for an RSC migration to be a win on TBT and JavaScript bytes, a
regression on LCP, and still worth pursuing for maintainability or future optimization. Say that
plainly.

## HiChee Case Study

A HiChee public-page conversion moved the home and FAQ pages to mostly static RSC output. Earlier
attempts produced misleading signals because they mixed package stacks, incomplete visual evidence,
missing asset setup, and hosted PageSpeed context that was not a clean local A/B.

The final merge confidence came from a local master-vs-PR ShakaPerf run on the same machine. It tested
home and FAQ in desktop and mobile viewports, paired visual regression with performance, used the
published package stack, and treated review-app or production PageSpeed as context rather than the
canonical merge signal. The published-stack run had clean visual diffs, materially lower JavaScript
and download bytes, and large mobile Lighthouse gains on the changed pages. A separate diagnostic run
against local framework main-tip packages was rejected because it failed visual parity, even though
some performance numbers looked better.

The key lesson is not "RSC always wins." The lesson is that RSC performance work needs a disciplined
evidence package: same-machine control/experiment, stable package stack, one variable per run,
archived parsed output, and visual parity as a merge gate.

## Follow-Up Diagnostics and Related Work

When the evidence points to unexpected RSC cost, use the existing troubleshooting guides before
changing architecture:

- [RSC render asset/cache diagnostics](https://github.com/shakacode/react_on_rails/issues/4296)
  tracks framework support for showing cache hit/miss state, emitted assets, client references, and
  payload size during benchmark runs.
- [Chunk contamination](rsc-troubleshooting.md#chunk-contamination) explains large unexpected chunks
  from shared `'use client'` modules.
- [Client Reference Scope and Empty `clientReferences`](rsc-troubleshooting.md#client-reference-scope-and-empty-clientreferences)
  explains why globally emptying `clientReferences` is not a safe general optimization.
- [#4111](https://github.com/shakacode/react_on_rails/issues/4111) tracks the RSC CSS and
  cross-page chunk bloat warning work.
- [react_on_rails_rsc#134](https://github.com/shakacode/react_on_rails_rsc/issues/134) tracks
  route-scoped client-reference manifests.
- [react_on_rails_rsc#145](https://github.com/shakacode/react_on_rails_rsc/issues/145) tracks tiny
  sidecar entries for mostly static RSC pages.
- [#4298](https://github.com/shakacode/react_on_rails/issues/4298) tracks the repo-local agent skill
  that operationalizes this workflow.

For mostly static pages that still need a few browser behaviors, continue with
[Mostly Static RSC Shell With a Tiny Sidecar](rsc-static-shell-sidecar.md).
