# RFC: Revisit Server Functions (`'use server'`) for Pro (#4874)

**Status:** RFC — open for maintainer decision
**Issue:** #4874 (discussion, P3, theme:modern-react)
**Spike evidence:** PR #4876 (non-shipping spike, confined to `react_on_rails_pro/spec/dummy`)
**Date:** 2026-08-12
**Decision owner:** justin808
**Prior decision records:** #3867 (strategy decision, recorded 2026-06-12), #3956 (Option C closure and
reopen gates, 2026-06-18)

## Summary

Issue #4874 asks three questions about a _faithful_ `'use server'` transport — real RPC, not sugar over
form-POST. This document answers them using the settled decision records plus fresh execution evidence from
the spike in PR #4876.

**Verdicts in one paragraph.** (Q1) Fidelity removes the semantic-masquerade objection that killed #3956 and
weakens the "new security surface" half of #3867's Option A rejection, but it does not touch the core
architectural objection: a server function still executes in the renderer VM without Rails models, session,
or database, so Rails-context mutations still belong to Rails controllers via `useRailsForm`. What remains is
a real but narrower value class — Node-executable functions that need no Rails context, plus read-your-writes
per-root RSC refresh. (Q2) The minimum viable scope is six toolchain-layer seams with zero renderer-protocol
and zero core-gem changes. (Q3) Promotion stays gated on the demand evidence #3956 already specified; gates
1–2 remain unmet today, so the recommendation is to keep #4874 parked at P3 with the
`needs-customer-feedback` label, filing no implementation issue until that evidence exists.

## Background: the settled decision stack

Two prior decisions govern this space, and they rejected two _different_ things for two _different_ reasons.
Keeping the objections distinct is the whole point of this RFC:

- **#3867 (decision recorded 2026-06-12) rejected Option A on architecture.** True Server Functions would run
  where the RSC runtime lives — the Node renderer — which has no Rails models, session, cookies, or CSRF. Any
  real mutation would proxy back into Rails over HTTP, "reintroducing the API hop they claim to remove, with
  new security surface." Option B (the Rails-native bridge) became the v1 mutation path; Option C (sugar) was
  deferred to #3956.
- **#3956 (closed not planned 2026-06-18) rejected Option C sugar on semantic masquerade.** A
  `'use server'`-shaped syntax compiling down to form-POST "cannot faithfully map `'use server'` RPC
  semantics"; it would be RPC-looking code that silently delivers form-POST semantics — "worse than offering
  no sugar at all." The closure recorded three concrete reopen gates (quoted verbatim in Q3 below).

Supporting state, verified 2026-08-12:

- `useRailsForm` + `ReactOnRails::Controller::FormResponders` shipped in #3942 (closing #3872); the Inertia,
  Next.js, and RSC-data-fetching migration guides have pointed at it since #4090.
- #3553 (derive RSC client references from the actual RSC graph) closed **completed** via PR #3556 — one of
  the reference-machinery items #3956 listed as gates is now resolved.
- #3811 (auto-bundled component identity) remains **open**.

## What changed since #3867

Two things — and it matters which one is genuinely new:

1. **`internal/planning/server-functions-implementation/01-initial-plan.md` is not new information.** It was
   authored 2025-12-04 (PR #2166) and _predates_ the #3867 decision by six months. #3867's options analysis
   explicitly cited it ("Option A is therefore scoped-but-unstarted, not unexamined"). The plan's existence
   alone could not justify reopening anything; #4874 was correct to frame it as a question rather than a
   proposal.
2. **The spike (PR #4876) is the genuinely new evidence.** It demonstrates a working end-to-end faithful
   round trip inside the Pro dummy app — client proxy → `encodeReply` → Rails POST with standard CSRF →
   execution inside the RSC bundle in the node-renderer VM → flight-serialized return value → client decode —
   with **zero renderer-protocol and zero core-gem changes**, by composing existing seams
   (`render_code_as_stream(is_rsc_payload:)`, the generic `renderingRequest` protocol, Rails CSRF, RSC
   payload streaming). Live results: `greet({name:"World"})` executed in a renderer worker (PID-verified),
   295–460ms dev-mode round trips; `addNumbers(20, 22)` → `42`. See the appendix for full evidence.

Additionally, one of #3956's mechanical gates (#3553) has since resolved, and #3811 has not. Neither changes
the demand picture.

## Q1 — Does a faithful implementation change the calculus?

Partially, and it is worth being precise about which objection moves and which does not. The recorded
objections decompose into three parts:

### 1. #3956's semantic masquerade: neutralized

The masquerade objection was about syntax implying semantics it does not deliver — RPC-looking code that is
actually a form-POST. A faithful transport has no masquerade to commit: the `'use server'` function really is
invoked as RPC, its arguments really are `encodeReply`-serialized, it really executes server-side, and its
return value really comes back flight-serialized. Fidelity is not a workaround for the objection; it
dissolves the objection's premise. (This is also why #3956's gate 3 — "the semantic-confusion footgun can be
designed out" — is now addressed; see Q3.)

### 2. #3867's "new security surface" half: weakened, not eliminated

The #3867 analysis assumed a renderer-side dispatch would bypass Rails middleware, forcing CSRF/auth to be
reimplemented.
The spike shows the opposite composition: the transport routes through a Rails controller, so the standard
Rails stack stays authoritative — CSRF verified live (token-less POST → 422 with the stock
`ReactOnRails.authenticityHeaders()` mechanism, no new token scheme), endpoint authorization can mirror the
existing `rsc_payload_authorizer` pattern, and action resolution is confined to a build-time allow-list (a
hostile id probe, `file:///etc/passwd#pwn`, returned a safe error without any request-derived module
resolution). Client-callable RPC endpoints are still a genuinely new surface that needs manifest and
deserialization discipline — Q2's security section itemizes it — but it is a _bounded, Rails-fronted_
surface, not the reimplement-CSRF-on-the-renderer scenario #3867 priced in.

### 3. #3867's architectural core: untouched

The function still executes inside the renderer VM. No ActiveRecord, no session, no cookies, no Rails
helpers. A server function that wants to touch Rails state still degenerates into a proxy back to Rails —
exactly the degeneration #3867 identified — and for that class `useRailsForm` remains strictly better:
Rails-owned strong params, validations, authorization, and error shapes with no extra hop. Fidelity changes
the _transport_; it does not change the _execution locus_, and the execution locus was the core objection.

### The honest remaining value class

What a faithful transport uniquely enables is the class of functions that are **Node-executable and need no
Rails context**: pure computation, calls to non-Rails services from server-side code, work adjacent to the
RSC cache — plus **read-your-writes composition**, where an execution is followed by a per-root RSC refresh
using Pro's existing refetch machinery (see Q2's re-render policy).

**Q1 verdict:** feasibility is settled — yes, a faithful implementation is possible, and cheaply on the
protocol side. Two of the three recorded objection-parts move. But the surviving architectural objection
means the feature's value is confined to the non-Rails-context class, and whether _that_ class justifies the
toolchain investment in Q2 is a product/demand question, not a feasibility one. That question is exactly what
Q3's gates measure.

## Q2 — Minimum viable scope

The spike's central scoping finding: everything missing is **toolchain-layer**. The blast radius is confined
to the RSC toolchain and Pro surfaces — **zero renderer-protocol changes, zero core-gem changes**.

### The six missing seams

| #   | Seam                                                                                                                                                    | Home                                                               |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1   | Client-bundle loader transform for `'use server'` modules (directive-aware, with a JSX-safe parser — see the acorn-loose follow-up in the appendix)     | `shakacode/react_on_rails_rsc` (webpack loader)                    |
| 2   | `createServerReference` / `encodeReply` client-runtime re-exports (so apps do not import `react-server-dom-webpack` internals directly)                 | Pro npm package (`packages/react-on-rails-pro`)                    |
| 3   | `FormData` in the renderer VM sandbox globals (`decodeReply` depends on it; the spike duck-typed around it)                                             | Node renderer VM (`packages/react-on-rails-pro-node-renderer`)     |
| 4   | `executeServerFunction` first-class RSC-runtime method plus a gem controller concern (replacing the spike's "executor mode" server-component smuggling) | Node renderer runtime + Pro gem                                    |
| 5   | Hashed action ids + server-reference manifest (the spike's `pathToFileURL(...)#export` ids leak absolute build paths and break multi-machine builds)    | `shakacode/react_on_rails_rsc` (loader + plugin manifest emission) |
| 6   | Action-scoped endpoint authorization (authorizer receives the action id + manifest metadata; see Security surface)                                      | Pro gem                                                            |

### Security surface

The endpoint is a client-callable RPC dispatcher, which is the class of surface Next.js has repeatedly
patched (e.g., CVE-2024-34351, SSRF via Server Actions). The spike's hostile-id probe demonstrates the shape
of the defense; a real implementation must make each item first-class:

- **Action-id allow-listing via a build-time manifest** (seam 5): only ids registered at build time are
  resolvable; nothing request-derived reaches module resolution. The spike verified this with a hostile id
  returning a safe error.
- **Argument deserialization limits:** `decodeReply` consumes attacker-controlled payloads; enforce a request
  size cap **before body materialization** (Rack-level `Content-Length` / streaming limit — the spike's 64KB
  check ran after `raw_post` had already buffered the body, which caps what reaches the renderer but not the
  Rails-side allocation), cap/validate the action-id header, and reject multipart/binary until separately
  scoped.
- **Authorization** (seam 6): **action-scoped**, not merely endpoint-scoped. Endpoint-level authz mirroring
  `rsc_payload_authorizer` only makes the dispatcher as reachable as the RSC payload endpoint; it does not
  prove the current user may invoke a _specific_ function — a privileged action's client reference can sit in
  a served chunk for anyone to replay. The authorizer must receive the action id (plus manifest metadata) and
  deny before renderer execution, the way `rsc_payload_authorized?(component_name)` scopes by component.
- **CSRF: unchanged.** The standard Rails token via `ReactOnRails.authenticityHeaders()` — verified live in
  the spike (token-less POST → 422). No new token scheme, consistent with #3867's recorded CSRF story.

### Re-render policy

Waku-style **execute-without-re-render** as the default; per-root refresh as an opt-in composed from Pro's
existing RSC refetch machinery (`getReactServerComponent.client.ts`). Next.js-style whole-app re-render does
not map to Pro's model — Rails owns the page shell, and a page has N independent roots. Next-style
read-your-writes semantics decompose into execute + per-root refresh, or a combined
`{returnValue, refreshedTree}` response.

### Separable follow-ups (not MVS)

- **Multipart/binary arguments** — `decodeReplyFromBusboy` exists server-side; client-side `encodeReply`
  multipart handling is separable.
- **Progressive enhancement / `useActionState`** — needs `decodeAction`/`decodeFormState` (already exported
  by the RSC stack) and is re-render-shaped; scope separately if the MVS ever lands.

## Q3 — What evidence gates promotion to implementation?

Adopt #3956's reopen gates verbatim as the promotion bar. From its closing comment (2026-06-18):

> Reopen only if **all** of these become true:
>
> 1. Next.js → React on Rails migration becomes a **primary, high-volume adoption channel** (not a documented
>    option but a measured inflow), **and**
> 2. There is **specific demand** for Server-Action-familiar syntax from those migrants — i.e., the
>    `useRailsForm` rewrite is measurably a migration blocker, **and**
> 3. The semantic-confusion footgun can be **designed out** — e.g., a deliberately RoR-named directive/helper
>    that does _not_ impersonate `'use server'`, so it cannot be mistaken for Next.js RPC semantics.

Updated status of each gate:

- **Gate 3 — now addressed by fidelity itself.** The footgun was syntax impersonating semantics it did not
  have. A faithful transport does not impersonate `'use server'` semantics; it implements them (for the
  non-Rails-context class, with the Rails-context boundary documented). The design-out that gate 3 asked for
  is what PR #4876 demonstrates.
- **Gates 1–2 — unmet.** A search across this repository's issues (2026-08-12) found every mention of server
  actions/functions to be maintainer-authored (#3867, #3956, #3872, #3900, #4445, #4874, #2164, and related);
  there is zero customer-reported demand, no measured migration inflow, and no report of the `useRailsForm`
  rewrite blocking a migration.

**Recommendation:**

- Keep #4874 open and parked at P3; add the `needs-customer-feedback` label ("do not implement until customer
  evidence or maintainer approval exists").
- File **no implementation issue** until gates 1–2 have evidence.
- If they ever do, the promotion path is ready-made: this document is the design record, PR #4876 is the
  execution evidence, and Q2 is the scoped issue breakdown. The cost of parking is near zero; the cost of
  building ahead of demand is six seams of toolchain across four homes, carried indefinitely.

## Relationship to the shipped Rails-native bridge

`useRailsForm` + `FormResponders` (#3942) remains **the** documented mutation path, and nothing in this RFC
proposes changing that. The migration guides (#4090) keep pointing at it. A future server-functions transport
would be **additive** — covering the Node-executable, no-Rails-context class that `useRailsForm` was never
meant to serve — and never a replacement for Rails-owned mutations. Any future docs for the transport must
state the boundary explicitly: functions that need Rails models, session, or authorization belong in Rails
controllers, reached via `useRailsForm`.

## Non-goals

- **No implementation issue** is filed by this RFC; that is gated on Q3's evidence (per #4874's own explicit
  non-goal).
- **No changes to the docs stance or migration guides** — the `'use server'` prohibition in the published
  docs stands while the decision is parked.
- **No renderer-protocol or core-gem changes** — and none would be needed per the spike; this line also marks
  the scope boundary any future implementation must respect.
- **No progressive-enhancement / `useActionState` design** — re-render-shaped, separately scoped.
- **No multipart/binary argument support** — separable follow-up.
- **No timeline commitment** — parking means parking.

## Appendix — Spike evidence (PR #4876)

- **PR:** [#4876](https://github.com/shakacode/react_on_rails/pull/4876) — "Spike: faithful 'use server'
  transport probes in Pro dummy app (#4874 RFC evidence)". Non-shipping; all code confined to
  `react_on_rails_pro/spec/dummy`.
- **Commits:** `702f27d3ae736d709996daee749f6eed0f9e2473` (transport probes),
  `3984fbf681dbec14460a9b578b1f1da08617291c` (three round-trip blockers fixed live).
- **Live results:** `greet({name:"World"})` →
  `{"message":"Hello, World! (executed inside the RSC bundle)",...,"processPid":38876}` (350ms);
  `addNumbers(20, 22)` → `42` (406ms); PIDs verified as node-renderer workers; token-less POST → 422 (CSRF);
  hostile id `file:///etc/passwd#pwn` → safe error. Dev-mode latency 295–460ms (unbenchmarked).
- **Reproduction:**

  ```bash
  cd react_on_rails_pro/spec/dummy
  pnpm install && bundle install && bundle exec bin/rails db:prepare
  pnpm run build:dev
  RENDERER_PORT=3821 pnpm exec node renderer/node-renderer.js &
  REACT_RENDERER_URL=http://localhost:3821 bundle exec bin/rails s -p 3021
  open http://localhost:3021/spike_server_functions
  ```

- **Incidental finding, independent of this RFC:** the published `react-on-rails-rsc` node-loader parses raw
  JSX with `acorn-loose`; loose recovery can swallow `export default` and silently emit an empty
  client-reference module (the component vanishes from the payload). Reproduced deterministically; affects
  existing `'use client'` users today. Follow-up: JSX-safe parsing in the `shakacode/react_on_rails_rsc`
  node-loader.

## References

- #4874 — this RFC's tracking issue (the three questions)
- #3867 — Server Functions strategy decision (Option C with B-first sequencing, recorded 2026-06-12)
- #3956 — Option C sugar, closed not planned (2026-06-18); source of the reopen gates adopted in Q3
- PR #4876 — spike evidence (this document's companion)
- #3942 / #3872 — `useRailsForm` + `FormResponders` (Option B, shipped)
- #4090 — migration guides updated to point at `useRailsForm`
- #3553 / PR #3556 — client references derived from the RSC graph (closed completed)
- #3811 — auto-bundled component identity (still open)
- `internal/planning/server-functions-implementation/01-initial-plan.md` — pre-decision Option A pipeline
  sketch (2025-12-04, PR #2166)
- CVE-2024-34351 — Next.js SSRF in Server Actions (the endpoint-surface CVE class motivating Q2's security
  section)
