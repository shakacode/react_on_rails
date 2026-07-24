# Product Strategy & Roadmap

The language used when planning React on Rails releases, triaging the backlog, and positioning against competitors. Exists so roadmap issues, triage passes, and marketing claims all mean the same thing by the same words.

## Language

**Pro install**:
A new Organization adopting React on Rails Pro in a real app — the roadmap's #1 goal metric, pursued through three funnels: new-app adoption, migration wins, and OSS→Pro upgrades.
_Avoid_: download count, npm installs (raw download breadth was explicitly rejected as the metric)

**Trust-based license**:
The Pro distribution model — packages freely installable with no key enforcement; Production Use requires a paid per-Organization subscription on the honor system, except where EULA v2.2 grants free use (evaluation, education, demos, and complimentary qualifying-open-source licenses under §4.1).
_Avoid_: freemium, open core

**Competitive frame**:
The Inertia+Vite stack (`inertia_rails` + `vite_ruby`) — the default "modern Rails + React" recommendation the roadmap positions against. Next.js/TanStack Start/React roadmaps are direction references, not the battleground.
_Avoid_: treating vite-rails alone as the competitor (it is a bundler layer; the rival is the full stack)

**Headline theme**:
One of the three roadmap pillars that get P0/P1 issues and the marketing narrative: Provable performance, Onboarding simplicity, Agent-native development.

**Provable performance**:
Performance claims backed by a public, reproducible artifact (e.g., the Gumroad RSC demo: ~48%/43% faster navigation, ~44% less HTML+JS vs the Inertia control). Popmenu is cleared for naming in public posts with CrUX-derived numbers (97% good LCP / 95% good INP; the Chrome UX Report is the public, independently queryable artifact backing them); lead with LCP/INP, never CLS or overall CWV (2026-07-17). Demo numbers are always "vs the Inertia control," never "faster than live Gumroad" (parity caveats: internal/analysis/2026-07-09-gumroad-pagespeed-parity-cautionary-tale.md).
_Avoid_: unbenchmarked "fast" claims, citing the ~36× PPR prototype before 17.2 ships its artifact

**Onboarding simplicity**:
Neutralizing Inertia's "one command and it works" edge for the new-app funnel — generator quality, zero-config defaults, time-to-first-success.

**Agent-native development**:
Making React on Rails the stack AI coding agents can install, build with, and debug unaided — llms.txt, MCP, AGENTS.md scaffolding, agent-legible errors.

**New-app path**:
`npx create-react-on-rails-app` — defaults to Pro (opt out via `--standard`); the quick-start leads with it. Distinct from the existing-app installer (`rails g react_on_rails:install`), which still defaults Pro off.

**Supporting theme**:
Roadmap work that feeds the headliners but doesn't lead the narrative: DX-parity features (forms, routing, caching answers to Inertia's useForm/Link), modern React coverage, production-readiness/observability, docs/content, demo fleet.

**Campaign north star**:
The goal metric of a time-boxed launch/promotion campaign, chosen per campaign. For the 17.0.0 launch it is OSS visibility (stars growth, HN/Reddit/X engagement, docs traffic) as the top of all three **Pro install** funnels: campaign copy teaches and shows numbers; Pro conversion is tracked as a secondary effect, not the campaign KPI. A later campaign may pick a different north star; OSS visibility is not a standing KPI.
_Avoid_: reusing "north star" unqualified — ROADMAP.md's "North star" section is the product vision, and the roadmap's #1 goal metric stays **Pro install**

**Pro disclosure line**:
The messaging policy for OSS venues (HN, Reddit, community Slacks): lead with the OSS story and include exactly one plain sentence that the RSC/streaming/node-renderer layer is the Pro package — source-available, free to install and evaluate under the **Trust-based license**, paid for production use unless an EULA free-use exception applies (education, demos, qualifying open source; see **Trust-based license**). Preempts the "open-core gotcha" comment.
_Avoid_: concealment (worse than the gotcha), Pro-forward leads in OSS venues

## Relationships

- Each **Headline theme** serves at least one **Pro install** funnel: Provable performance → all three; Onboarding simplicity → new-app; Agent-native → new-app (agents increasingly choose the stack).
- **Supporting themes** exist to remove objections within the **Competitive frame**, not to headline releases.
- The **Trust-based license** makes **Pro install** an adoption metric first and a revenue metric second.

## Example dialogue

> **Dev:** "Inertia shipped a new `useForm` feature — do we headline a response in 17.1?"
> **Maintainer:** "No — forms are a **supporting theme** (DX parity). It ships, but the release headline stays on a **headline theme**, like PPR numbers we can prove publicly."

## Flagged ambiguities

- "installs" was used to mean both raw package downloads and real adoptions — resolved: **Pro install** means an Organization adopting Pro in a real app; raw downloads rejected as a goal metric (2026-07-11).
- "vite-rails as competitor" — resolved: the **Competitive frame** is the full Inertia+Vite stack; bundler-level Vite DX is a supporting concern, not the anchor (2026-07-11).
- "north star" was overloaded between ROADMAP.md's product-vision statement, the roadmap goal metric, and launch-campaign KPIs — resolved: the 17.0.0 launch campaign's **Campaign north star** is OSS visibility (per-campaign, not standing); the roadmap's #1 goal metric remains **Pro install** (2026-07-17).
- How loud Pro may be in OSS launch venues — resolved: the **Pro disclosure line** (own it in one sentence), rejecting both OSS-only concealment and Pro-forward leads (2026-07-17).
