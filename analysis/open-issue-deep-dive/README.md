# Open Issue Deep Dive (2026-03-22)

## Snapshot

- Open issues reviewed: 85
- Open issues already linked to an open PR: 10
- Open issues without an open PR at review time: 75
- Wave 1 (PR #2810): 34 issues
- Wave 2 (stacked follow-up PR): 20 issues
- Wave 3 (stacked follow-up PR): 21 issues
- Triage comments posted at snapshot time: 85/85

## Existing Open PR Coverage
- #2802 RSC migration docs: fix fictional API names, missing associations, form_with, and CSRF token patterns -> #2803
- #2794 Track B: add react_on_rails:sync_versions for gem/npm lockstep -> #2797
- #2781 Docs: Add missing content pages (RSC landing, ExecJS, debugging, benchmarks) -> #2785
- #2766 upload-assets endpoint copies all files into all target bundle directories, duplicating bundles -> #2768
- #2614 Replace NDJSON envelope with length-prefixed protocol for Node→Ruby streaming -> #2615
- #2526 RSC migration docs: Structural and framing improvements -> #2661
- #2496 Tracking: Improve RSC/Pro demo DX, version sync, and safety checks -> shakacode/react_on_rails#2797, shakacode/react_on_rails-demos#112
- #2457 Make bundle hash depend on asset content for fully immutable bundle directories -> #2534
- #2347 Enhancement: Extensible bin/dev precompile pattern as alternative to precompile_hook -> shakacode/react_on_rails-demos#112
- #1960 feat: add Lefthook for Git hooks management -> shakacode/package_json#32, shakacode/react_on_rails-demos#112

## Wave Definitions

- `wave-1`: active / near-term items (P1/P2, release-critical, or newly created issues with concrete implementation scope)
- `wave-2`: medium backlog (primarily P3 created in recent cycles)
- `wave-3`: long-tail backlog / parked items

## Format Notes

- Context excerpts in wave files are intentionally truncated with `...`.
- `Triage note` captures inferred scope, blocker history, pending verification, and other non-quoted analyst context.
## Execution Notes

- Every issue received a triage comment with domain, current PR coverage, and a concrete next-step question.
- New PR stack references all issues that had no open PR at review time.
