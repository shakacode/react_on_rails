# Gumroad PageSpeed Parity Cautionary Tale

## Verdict

The Gumroad RSC marketplace demo should not claim a public PageSpeed win against live Gumroad until the compared pages
have documented media, chrome, CDN, cache, host, and browser parity. A PageSpeed filmstrip/timeline check caught the
problem: the demo page being praised had little or no product imagery, while the live Gumroad page loaded production
images and production page chrome. That was not an apples-to-apples comparison.

The corrected evidence model is:

1. Use same-host ShakaPerf A/B runs for the architecture claim: matched Inertia control versus React on Rails Pro RSC
   candidate, same fixture, same host, same browser settings.
2. Use PageSpeed and Lighthouse links as diagnostics until the demo fixture has production-equivalent media and surface
   parity.
3. Label historical, pre-media, review-app, local, stable-deployed, and live-external results separately.
4. Wait for React on Rails Pro `17.0.0` final before posting upstream advocacy that depends on final package status.

## What Happened

The public demo goal was good: show whether React Server Components through React on Rails Pro can make Gumroad-style
public marketplace pages faster than the Inertia status quo. The initial PageSpeed comparison looked favorable for the
demo, but the PageSpeed timeline revealed a fixture mismatch:

- the demo route did not yet load equivalent product/card images;
- live Gumroad loaded real production images and more production chrome;
- therefore the demo had less work to do before first paint and LCP;
- quoting the score as proof would have overstated the architecture win.

This is the exact failure mode performance demos must avoid: the benchmark is technically reproducible, but it measures
a cheaper page.

## Corrected Evidence

The Gumroad demo PR switched the headline evidence to a media-bearing, same-fixture ShakaPerf run on the PR review app:

| Surface              | Median navigation        | Median LCP             | JavaScript requests | Note                |
| -------------------- | ------------------------ | ---------------------- | ------------------- | ------------------- |
| Product detail       | `1292.15ms -> 731.70ms`  | `992.00ms -> 382.00ms` | `9 -> 1`            | RSC wins with media |
| Discover marketplace | `1423.70ms -> 1054.30ms` | `960.00ms -> 602.00ms` | `9 -> 1`            | RSC wins with media |

The same run also recorded tradeoffs: larger server-rendered HTML, larger media-bearing RSC route JavaScript in that
run, and slower response-end because more complete content is present in the document. Those tradeoffs belong next to
the win.

The PR also changed reproduction commands so a review-app page points ShakaPerf at the current host instead of the
stable pre-media deployment. Otherwise a reader could copy the command from the PR page and unknowingly measure the
wrong site.

Reference case study: [shakacode/react-on-rails-demo-gumroad-rsc#69](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/69).

## Performance Claim Checklist

Before a React on Rails or React on Rails Pro demo claims a public-page speedup, require this checklist in the PR body,
issue, or internal analysis note:

- **Comparator is named.** State whether the evidence is same-fixture A/B, review-app versus stable, stable versus live,
  local twin-stack, or external diagnostic.
- **Fixture parity is visible.** Screenshots or filmstrips show that key product images, cards, fonts, page chrome, and
  above-the-fold content exist on both sides.
- **Host parity is explicit.** Commands and links point to the same host that produced the headline artifact, or they
  are labeled as a fresh rerun on the currently viewed host.
- **PageSpeed is classified.** PageSpeed/Lighthouse against live external URLs is diagnostic unless production-service,
  CDN, cache, media, and page-surface differences are documented.
- **Artifacts are reproducible.** Store run count, warmups, browser/driver versions, URL pairs, route paths, commit SHA,
  and parsed JSON output.
- **Historical results are labeled.** Pre-media, pre-optimization, local-only, review-app-only, and stable-deployed
  results must not share one "current" label.
- **Tradeoffs are adjacent to wins.** Include HTML size, response-end, JavaScript bytes/requests, cache state, and any
  missing metric instead of publishing only favorable numbers.
- **Visual parity gates performance.** A faster page missing visible UI is a failed experiment, not a win.
- **Copy-paste commands are safe.** The command shown on a review app must not silently benchmark the stable site; the
  command shown on stable must not silently benchmark a deleted review app.

## Applying This To React on Rails Pro RSC Demos

For public-facing marketplace, marketing, docs, and content pages:

- prefer a small but realistic fixture over a minimal fixture that flatters RSC;
- make image loading real, even when using local synthetic images;
- keep cached/static RSC variants separately named from uncached matched-route comparisons;
- measure visual parity and performance in the same review cycle;
- use ShakaPerf or an equivalent paired harness for the headline claim;
- use PageSpeed, Lighthouse, WebPageTest, or production RUM to corroborate after parity is proven.

Good wording:

> On a media-bearing same-host ShakaPerf A/B run, the RSC route improved median LCP from X to Y versus the matched
> Inertia control. Live PageSpeed links are diagnostic until media, chrome, CDN, and cache parity are documented.

Bad wording:

> The demo beats live Gumroad on PageSpeed.

The bad version hides the comparator and encourages readers to infer that the architecture caused the whole score gap.

## Follow-Up Actions

- Keep this checklist aligned with `.agents/skills/optimize-rsc-performance/SKILL.md`.
- When a demo page includes PageSpeed links, place the caveat next to the links, not only in a separate doc.
- When a PR changes fixtures, images, page chrome, or generated HTML, refresh the headline artifact or downgrade older
  artifacts to historical support.
- After React on Rails Pro `17.0.0` final is available and the stable Gumroad RSC demo has media parity, rerun the
  stable PageSpeed/Lighthouse comparison before opening an upstream Gumroad issue.
