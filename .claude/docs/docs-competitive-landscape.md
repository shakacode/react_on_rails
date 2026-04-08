# React on Rails Competitive Documentation Landscape

Reference for understanding what competitors offer so documentation can match or exceed them.

## React on Rails Competitors

### Inertia Rails (inertia-rails.dev)

Doc site structure (VitePress at inertia-rails.dev):

- Introduction, Demo app, Upgrade guide
- Installation: Server-side, Client-side, Starter kits
- Core concepts: Who is it for, How it works, The protocol
- The basics: Pages, Responses, Redirects, Routing, Title & meta, Links, Manual visits, Forms, File uploads, Validation, View transitions
- Data & Props: Shared data, Flash data, Partial reloads, Deferred props, Polling, Prefetching, Load when visible, Merging props, Once props, Infinite scroll, Remembering state
- Security: Authentication, Authorization, CSRF protection, History encryption
- Advanced: Asset versioning, Code splitting, Configuration, Error handling, Events, Progress indicators, Scroll management, SSR, Testing, TypeScript
- Extras: Cookbook, Awesome list

Key differentiators:

- LLMs.txt and llms-full.txt for AI agents
- "Are you an LLM?" notice on every page
- Cookbook with practical recipes (shadcn/ui integration, etc.)
- Three official starter kits
- Every page editable on GitHub

### Vite Ruby (vite-ruby.netlify.app)

Doc site structure:

- Introduction (motivation, comparison)
- Getting Started (multi-framework install)
- Development, Deployment, Advanced, Plugins
- Rails Integration (tag helpers, asset handling)
- Configuration Reference (every option in a table)
- Troubleshooting
- Overview (internals for curious devs)

Key differentiators:

- Clear framework-specific install paths
- Recommended plugins page
- Link to example app on Heroku

### react-rails gem (github.com/reactjs/react-rails)

- Single long README
- Wiki with community-contributed articles
- No dedicated docs site
- Outdated examples in some areas
- Migration guide to React on Rails exists (this is an opportunity)

### Hotwire / Turbo (not a direct competitor but adjacent)

- Integrated into Rails official guides
- Handbook at hotwired.dev
- Clear separation: Turbo Drive, Turbo Frames, Turbo Streams

## What React on Rails Should Target

Based on competitive analysis, the minimum viable docs improvement:

1. **Match Inertia Rails' structure** for doc site sidebar organization
2. **Add LLMs.txt** (Inertia Rails has this; we should too)
3. **Create a real Configuration Reference page** (Vite Ruby does this well)
4. **Troubleshooting page** derived from top GitHub Issues
5. **Cookbook section** with recipes for common setups (TypeScript, Redux, React Router, Tailwind, shadcn/ui)
6. **Comparison page** that honestly compares React on Rails vs. Inertia vs. Vite Ruby vs. react-rails
7. **Demo app** with source code and live link
8. **Upgrade guides** for each major version with before/after code
9. **AI agent instructions** (already exists, keep it updated)

## Unique Strengths to Highlight in Docs

- 10+ years of production use
- Server-side rendering built in (Inertia only recently added SSR)
- React Server Components support (via Pro)
- Works with existing Rails views (progressive adoption)
- No client-side routing required
- Rspack support for faster builds
