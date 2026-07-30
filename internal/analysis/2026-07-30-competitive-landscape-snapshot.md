# Competitive Landscape Snapshot — 2026-07-30

Point-in-time survey of the libraries competing for "modern React on a Rails backend" mindshare,
taken two weeks after React on Rails 17.0.0 shipped (17.0.1 current since 2026-07-29). Gathered
via registry APIs (npm, RubyGems, GitHub) and primary sources (release notes, official blogs) on
2026-07-30. Claims that could not be verified against a primary source are marked UNVERIFIED.

Companion docs: the standing **Competitive frame** definition in
[internal/planning/CONTEXT.md](../planning/CONTEXT.md) (unchanged by this snapshot: the battleground
remains Inertia+Vite), the architecture deep-dives in
[nextjs-turbopack-rsc-vs-react-on-rails-pro.md](./nextjs-turbopack-rsc-vs-react-on-rails-pro.md)
(2026-06-17) and
[nextjs-vs-react-on-rails-pro-async-streaming.md](./nextjs-vs-react-on-rails-pro-async-streaming.md)
(2026-07-13), and [ADR 0001](../adr/0001-rspack-answers-vite.md) (Rspack answers Vite).

## Snapshot table

React on Rails baseline: v17.0.1 (2026-07-29), 5,190 GitHub stars, ~81–95k npm downloads/week.

| Library                      | Current version (date)                                             | Momentum                                                                      | RSC story                                                                       |
| ---------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Inertia.js core              | v3.6.1 (2026-07-07); v3.0 shipped 2026-03-25                       | 8,079 stars; @inertiajs/core ~1.01M npm/wk, react adapter ~603k/wk            | None shipped; no announced ambitions (anti-RSC statement: UNVERIFIED)           |
| inertia_rails                | 3.22.0 (2026-07-17)                                                | 1,215 stars; 1.75M gem lifetime; ~monthly releases                            | n/a (follows core)                                                              |
| vite_rails / vite_ruby       | 3.11.1 (2026-07-03) / 3.10.2 (2026-03-30)                          | 1,591 stars; 35.8M/37.2M lifetime; single-maintainer upkeep                   | n/a (bundler layer)                                                             |
| TanStack Start               | 1.168.33 (2026-07-29); still officially Release Candidate          | router monorepo 14,869 stars; react-start ~17.2M npm/wk (transitive-inflated) | Explicitly not in v1; experimental, planned as non-breaking v1.x addition       |
| Next.js                      | 16.2.12 (2026-07-25); 16.3-preview.10 (2026-07-28)                 | 141,175 stars; ~54.7M npm/wk                                                  | The only stable production RSC; Cache Components (`use cache` + PPR) since 16.0 |
| React Router (Remix lineage) | v8.0 shipped 2026-06-17; 8.3.0 (2026-07-22)                        | 56,533 stars; ~46.8M npm/wk                                                   | Still `unstable_`-prefixed at 8.3.0, changelog says not production-recommended  |
| react-rails                  | 3.3.1 (2026-05-16) after a ~2-year gap                             | 6,772 stars; caretaker mode                                                   | None; no SSR/streaming investment                                               |
| Turbo / turbo-rails          | 8.0.23 / 2.0.23 (both 2026-01-29, nothing since)                   | 7,370 stars; ~1.06M npm/wk                                                    | n/a (argues against React entirely)                                             |
| superglue (thoughtbot)       | gem 1.1.1 stable; v2 in beta all 2026                              | 609 stars; 26.5k gem lifetime                                                 | None                                                                            |
| tombolo (new 2026 entrant)   | 0.10.0 (2026-02-17)                                                | 4,349 gem lifetime                                                            | Optional ExecJS SSR only                                                        |
| React (context)              | 19.2.8 stable (2026-07-21); 19.3 canaries only (timing UNVERIFIED) | ~163M npm/wk                                                                  | PPR APIs + `<Activity>` landed in 19.2.0                                        |

Key 2026 facts behind the table:

- **Inertia v3.0** (2026-03-25) dropped React <19 and CJS, removed axios (built-in client +
  `useHttp`), added optimistic updates and Vite-dev SSR; prefetch/deferred props/polling date to
  v2.0 (2024-12-13), `<InfiniteScroll>` to v2.2 (2025-09-26). Evil Martians confirmed inside
  inertia_rails (16 of the last 30 commits by @skryukov; they run inertia_rails-contrib, starter
  kits, workshops). 3.22.0 included security hardening (cross-variant 304 poisoning fix).
- **Next.js 16** (2025-10-21) made Turbopack the default and shipped Cache Components; 16.2
  (2026-03-18) claimed ~400% faster dev startup and agent-ready scaffolding + DevTools MCP; 16.3
  previews add Instant Navigations (Stream/Cache/Block) and Partial Prefetching. Next also stood up
  a formal Security Release Program (July 2026) after the Dec 2025 RSC protocol RCE
  (CVE-2025-66478, CVSS 10.0) and a July 2026 batch (4 HIGH / 5 MEDIUM).
- **React Router v8** (2026-06-17): ESM-only, React 19.2.7+, monthly minors; RSC framework mode
  iterating fast but still unstable at 8.3.0.
- **Rails 8.1** (2025-10-22) changed no frontend defaults; current 8.1.3.1 (2026-07-29). No new
  DHH framework messaging found in 2026 (UNVERIFIED beyond standing no-build advocacy); expect
  fresh messaging at Rails World 2026 (Sept 23–24, Austin).

## What changed vs the 2026-06/07 deep-dives

1. **The stable-RSC window is real and closing.** Mid-2026, stable production RSC exists only in
   Next.js — React Router still ships it `unstable_`, TanStack Start marks it experimental, Inertia
   has nothing. React on Rails Pro 17 on stable React 19.2 is therefore the only Rails stack — and
   one of the very few stacks anywhere outside Next.js — shipping RSC as stable production
   software. React Router's monthly cadence (v8.4 expected mid-August) is the clock on that claim.
2. **Inertia is now agency-backed, not just community-run.** Evil Martians' confirmed investment
   raises the Competitive frame's release cadence and content volume. Laracon US ended 2026-07-29,
   so Inertia buzz is peaking in exactly the window our launch posts go out; comparison content
   must stay factual-not-combative (their v3 is genuinely good; our edge is SSR depth, RSC,
   streaming, and provable performance tooling they structurally lack).
3. **Turbo's silence weakens the in-house alternative.** Six months without a release undercuts
   "Hotwire is the modern default" for React-needing teams; our copy still never argues
   React-vs-Hotwire (per the launch plan), but the "when to choose what" docs page can note release
   cadence factually.
4. **RSC security is now a mainstream topic.** Next's CVE history plus our own July RSC security
   audit (no critical/high findings; see internal notes from 2026-07) makes "RSC without the CVE
   treadmill, audited" a credible supporting angle for Pro conversations — supporting, not
   headline, since absence-of-CVEs is partly absence-of-attention at our scale.

## News hooks (next 2–4 weeks)

| Window           | Event                                           | Use                                                                                                                                                   |
| ---------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Now              | Laracon US just ended (Jul 28–29)               | Inertia comparison content lands while the topic is hot; strictly factual tone                                                                        |
| Early Aug        | Next.js 16.3 stable imminent (preview.10 out)   | Comment/react content: Instant Navigations vs our PPR direction (no 17.2 numbers before the artifact ships)                                           |
| Mid Aug          | React Router v8.4 on the monthly cadence        | THE watch item: any RSC stabilization ends our exclusivity claim; pre-draft the "state of RSC outside Next" piece so we publish within 48h either way |
| Any week         | TanStack Start declares 1.0 stable              | Ride-along: our TanStack starter + typed-contracts story                                                                                              |
| Aug → Sept 23–24 | Rails World 2026 (Austin) pre-conference window | CFP/talk prep + "React on Rails at Rails World" content series                                                                                        |

## Threat ranking (most → least direct)

1. **Inertia + inertia_rails** — same buyer, same promise, monthly cadence, agency muscle; wins by
   default in new Rails+React apps.
2. **Next.js 16** — owns the "modern React" definition and pulls whole teams off Rails; sets the
   RSC/PPR bar.
3. **TanStack Start** — the explicit-control crowd's choice; pairs with Rails-as-API and hollows
   out the Rails view layer.
4. **React Router v8** — the biggest installed base racing us to production RSC outside Next.
5. **Hotwire/Turbo** — argues Rails apps need no React; dormant in 2026.
6. **superglue** — thoughtbot halo, v2 still beta, adoption ~1000x smaller.
7. **react-rails / tombolo** — legacy caretaker and a hobby-scale newcomer; migration sources.
8. **Vite Ruby** — complement, not competitor; strengthens the Inertia stack's DX.

## Implications for current priorities

- The 17.0 launch campaign's strongest time-sensitive line is now: **stable RSC + streaming on
  Rails today, while everyone else's RSC is unstable, experimental, or absent** — with the honest
  scope caveat (Next.js has it; we are the Rails path). Copy assets updated accordingly in the
  campaign folder (sc-articles).
- Do not lead with Inertia-negative framing in the Laracon afterglow; lead with our numbers and the
  "when to stay on Inertia" honesty that reviewers consistently reward.
- Pre-draft the React-Router-v8.4 contingency piece before mid-August.
- Rails World 2026 planning (talk, booth-adjacent content, demo fleet freshness) should enter the
  roadmap by mid-August.
