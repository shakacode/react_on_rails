---
status: accepted
date: 2026-07-17
---

# Agent toolchain ships as Skills-in-package; slim MCP deferred to eval evidence

AI coding agents are a first-class adoption funnel (**Agent-native development** is a headline theme), and the question of _how_ React on Rails exposes itself to agents was reopened by 2026-07 ecosystem evidence: Next.js 16.3, TanStack, and Inertia Rails all converged on agent content shipped **inside the installed package** (SKILL.md files, version-matched bundled docs) with at most a deliberately slim tool surface. We decided (#4605, 2026-07-17) that the 17.2 agent flagship is **Skills-in-package plus version-matched bundled docs**: the gem and npm packages carry SKILL.md files for the high-value flows (install/upgrade, RSC adoption, streaming debug, doctor-driven fixloop), and scaffolded AGENTS.md points at docs shipped in the installed package rather than only the live site. A **slim MCP** (at most doctor + compile-diagnostics tools) stays deferred until the 17.1 agent-tutorial eval (#4603) produces evidence that Skills + doctor-JSON are insufficient. The June 2026 ruling closing the full MCP server (#3870, NOT_PLANNED) stands.

## Considered options

- **Full MCP server** (#3870) — rejected 2026-06-18 and still rejected: every capability it would expose is already served for shell-capable agents by scaffolded AGENTS.md + `react_on_rails:doctor` + docs.
- **Slim MCP now** (doctor + compile-diagnostics tools in 17.2) — rejected pending evidence: the #4603 eval exists precisely to measure whether an agent can build a Pro app unaided with Skills + doctor-JSON; committing MCP surface before that data would be speculation with a permanent maintenance cost.
- **Docs/llms.txt only, no Skills** — rejected: version skew is the failure mode the ecosystem is actively fleeing ("NOT the Next.js you know"); content that ships with the code is version-matched by construction, and Skills are the shape Claude Code/Cursor/Codex actually consume.

## Consequences

- Skills live in the packages, so they version with the code and are testable in CI; the 17.1 eval harness (#4603/PR #4614) becomes the regression gate for agent-flow quality.
- The scaffolded AGENTS.md block gains a pointer to bundled docs; the live-site pointer stays as the secondary reference.
- Revisit trigger for the slim MCP: the #4603 eval failing on capabilities that Skills + doctor-JSON structurally cannot provide (e.g., compile-diagnostics streaming), or a major agent platform dropping filesystem skill discovery.
