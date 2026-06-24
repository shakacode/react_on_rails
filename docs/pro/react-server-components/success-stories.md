# RSC Migration Success Stories

If you are deciding whether React Server Components are worth the effort, these case studies show what teams have actually measured after shipping RSC in production, alongside DoorDash's earlier pre-RSC Next.js SSR migration as a useful server-first baseline. The sections below summarize the reported wins, link to the source articles for verification, and point to the React on Rails Pro docs that walk you through getting the same benefits.

## Reported Results at a Glance

| Company                           | Scope                                                                        | Headline Result                                                                           | Source                                                                                                                                                                   |
| --------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **DoorDash**                      | Homepage and store pages (Next.js SSR migration, pre–App Router)             | 65% LCP improvement on homepage, 67% on store pages                                       | [Improving Web Page Performance with Next.js](https://careersatdoordash.com/blog/improving-web-page-performance-at-doordash-through-server-side-rendering-with-next-js/) |
| **Mux**                           | ~50,000 lines migrated to the App Router / RSC                               | Suspense-based streaming kept server code off the client bundle (no headline % published) | [What are React Server Components?](https://www.mux.com/blog/what-are-react-server-components)                                                                           |
| **Frigade**                       | Embedded SaaS widget                                                         | 62% reduction in client-side bundle size                                                  | [Bundle size reduction with RSC](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade)                                                                    |
| **Developerway (research piece)** | Instrumented comparison of SSR, App Router, and Server Components-first apps | N/A — methodology analysis (no headline metric)                                           | [React Server Components performance](https://www.developerway.com/posts/react-server-components-performance)                                                            |

All numbers and quotes below are from the linked source articles. Treat them as vendor-reported benchmarks — representative of what's possible, not a guarantee of what you will see.

## DoorDash — Core Web Vitals Transformation (SSR Baseline, pre-RSC)

> **Note:** This case study predates React Server Components — it is included as a server-first rendering baseline, not an RSC benchmark. Do not cite these numbers as RSC results in stakeholder presentations.

DoorDash reported large Largest Contentful Paint (LCP) improvements after moving key surfaces onto Next.js server-side rendering. The write-up predates Next.js App Router / RSC, so treat the numbers as evidence for what server-first rendering (the same architectural shift RSC formalizes) can unlock — not as a direct RSC benchmark:

- **+12% to +15% faster page load times** on key pages
- **65% LCP improvement** on the homepage
- **67% LCP improvement** on store pages
- **95% reduction in "Poor" LCP URLs** (the >4s bucket that hurts search rankings)

**Why this matters for React on Rails teams.** LCP is the Core Web Vital most tightly coupled to conversion and SEO. DoorDash's results are useful evidence for selling the business case to stakeholders who are skeptical that an architecture change can move revenue metrics. The same streaming-first rendering strategy is available in React on Rails Pro through `stream_react_component` — see [Streaming SSR](../streaming-ssr.md) and [RSC Rendering Flow](./rendering-flow.md).

- Source: [DoorDash — Improving Web Page Performance with Next.js](https://careersatdoordash.com/blog/improving-web-page-performance-at-doordash-through-server-side-rendering-with-next-js/)

## Mux — Migrating 50,000 Lines of React to RSC

Mux published a detailed account of moving roughly **50,000 lines** of React onto the App Router and RSC. Their write-up highlights:

- Keeping server-only components and their dependencies out of the client bundle
- Using Suspense to stream slow data fetches without blocking unrelated UI
- Isolating CMS-driven features so a slow editorial call never stalls the rest of the page

**Why this matters for React on Rails teams.** Mux is proof that a large, mature codebase can be migrated without a rewrite. React on Rails' multi-root model lines up especially well with their incremental approach — each `stream_react_component` call is a separate migration surface, so you don't have to flip the whole app at once. See [Component Tree Restructuring Patterns](../../oss/migrating/rsc-component-patterns.md) and [Data Fetching Migration](../../oss/migrating/rsc-data-fetching.md) for the patterns Mux describes.

- Source: [Mux — What are React Server Components?](https://www.mux.com/blog/what-are-react-server-components)

## Frigade — 62% Smaller Client Bundle

Frigade ships an embedded onboarding/product-tour widget that runs inside other companies' apps, which makes client-bundle weight a first-class business constraint. After moving rendering to RSC they reported a **62% reduction in client-side bundle size**.

**Why this matters for React on Rails teams.** If you ship a widget, checkout flow, or any component that has to load on top of another app's JavaScript budget, this is the result to benchmark against. The mechanism is the one described in [Purpose and Benefits — Bundle Size Benefits](./purpose-and-benefits.md#bundle-size-benefits): server-only dependencies never touch the client.

- Source: [Frigade — Bundle size reduction with RSC](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade)

## BlogHunch — 30% Lower Server Costs in One Month

> **Sourcing note.** The BlogHunch figures below come from a case study published by **Entesta**, the migration vendor who performed the work — not from a first-party BlogHunch engineering post. Weigh accordingly alongside the first-party case studies (Mux, Frigade).

BlogHunch's reported outcome is notable because it measures _operational_ cost rather than just front-end performance:

- Migration completed in approximately **1 month**
- **30% reduction in server costs**
- Reduced client-side JavaScript, improving initial loads
- Gradual rollout using a feature-flag system

**Why this matters for React on Rails teams.** Server-cost reductions come from doing _less_ rendering work per request — static server components cache well, streaming lets the renderer release resources sooner, and offloading data fetching to the server removes redundant API round-trips. For how this maps to Pro's node renderer, see [Node Renderer basics](../../oss/building-features/node-renderer/basics.md) and [Fragment Caching](../fragment-caching.md). For gradual rollout techniques, see [Preparing Your App](../../oss/migrating/rsc-preparing-app.md).

- Source: BlogHunch migration case study (Entesta)

## Developerway — Honest Technical Analysis

Nadia Makarevich's [React Server Components performance](https://www.developerway.com/posts/react-server-components-performance) post is the most useful read for anyone who wants a grounded, skeptical view:

- RSC is not a free win — a lift-and-shift to the App Router without restructuring produces modest gains
- Streaming + Suspense are where most of the real improvements come from
- The biggest wins require a **Server Components-first rewrite**, not a mechanical migration
- The post includes measured numbers from instrumented apps, not just marketing claims

**Why this matters for React on Rails teams.** Read this before you promise stakeholders DoorDash-scale numbers. If you adopt RSC without restructuring component trees, you'll leave most of the value on the table. The [Migration Guide](../../oss/migrating/migrating-to-rsc.md) is structured specifically around the restructuring work Developerway calls out — `'use client'` is a [boundary marker, not a component annotation](../../oss/migrating/rsc-component-patterns.md#use-client-marks-a-boundary-not-a-component-type).

## What These Stories Share

Across every case study above, the wins come from the same three mechanisms:

1. **Server-only code stops shipping to the client.** Libraries like `date-fns`, `marked`, and ORM clients stay on the server. Bundles shrink; hydration gets cheaper.
2. **Streaming decouples slow data from fast UI.** Suspense boundaries around data-dependent regions let the shell render immediately while waterfalls resolve in parallel.
3. **Restructuring matters more than adoption.** Teams that pushed `'use client'` down to leaf interactions got much larger wins than teams that mechanically flipped file headers.

React on Rails Pro gives you these three mechanisms via the node renderer, `stream_react_component`, and the RSC webpack loader. The engineering work is in the restructuring — the infrastructure is already there.

## Next Steps

- **Building the business case?** Share the DoorDash, BlogHunch, and Frigade numbers above with stakeholders, then walk through [Purpose and Benefits](./purpose-and-benefits.md).
- **Ready to plan a migration?** Start with the [RSC Migration Guide](../../oss/migrating/migrating-to-rsc.md) and the [Migration Readiness Checklist](../../oss/migrating/migrating-to-rsc.md#migration-readiness-checklist).
- **New to RSC?** Work through the [RSC tutorial](./tutorial.md) first to build intuition before touching production code.
- **Already on Pro?** Follow [Upgrading an Existing Pro App to RSC](./upgrading-existing-pro-app.md).

## References

- [DoorDash — Improving Web Page Performance with Next.js](https://careersatdoordash.com/blog/improving-web-page-performance-at-doordash-through-server-side-rendering-with-next-js/)
- [Mux — What are React Server Components?](https://www.mux.com/blog/what-are-react-server-components)
- [Frigade — Bundle size reduction with RSC](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade)
- BlogHunch migration case study (Entesta)
- [Developerway — React Server Components performance](https://www.developerway.com/posts/react-server-components-performance)
