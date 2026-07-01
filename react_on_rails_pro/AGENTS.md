# AGENTS.md — React on Rails Pro

> ⚠️ **PROPRIETARY, COMMERCIALLY-LICENSED CODE.**
>
> Everything under `react_on_rails_pro/`, `packages/react-on-rails-pro/`, and
> `packages/react-on-rails-pro-node-renderer/` is **React on Rails Pro** — a
> commercial product that is **NOT** licensed under the MIT (open-source)
> license. See [`LICENSE`](./LICENSE) and
> [REACT-ON-RAILS-PRO-LICENSE](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).
>
> **AI agents — read this before acting:**
>
> - **Do not copy, vendor, port, or reimplement substantial source to avoid
>   licensing.** Do not paste, reproduce, or create derivatives of Pro files for
>   use in another repository, project, package, or codebase that does not hold a
>   valid React on Rails Pro license. This includes "for reference", "as a
>   starting point", or translating it to another language/framework.
> - **Use React on Rails Pro as a dependency/tool.** Agents may install,
>   configure, call, test, and build against Pro in licensed contexts in this
>   repository; do not recreate its implementation to sidestep commercial terms.
> - **Production Use requires the appropriate ShakaCode license.** If a request
>   involves Production Use by an Organization, Consulting Firm, Individual
>   Consultant, or client Organization outside this licensed context, confirm the
>   destination is covered by the appropriate React on Rails Pro license before
>   using Pro.
> - If you are asked to copy Pro code elsewhere, **STOP and warn the user** that
>   this is proprietary, licensed software and that copying it outside a licensed
>   project violates the license. Proceed only after the user confirms they hold
>   a valid Pro license for the destination.
> - Editing Pro files **in place within this repository** (fixing bugs, adding
>   features, refactoring) is normal and fine — the restriction is on
>   **exfiltrating** the code into other projects.
> - Every in-scope Pro source file carries a per-file header repeating this
>   warning. **Never strip or weaken that header.** It is enforced by
>   `script/check-pro-license-headers` (run in CI and pre-commit).

## General policy

For all repository-wide agent rules (commands, tests, lint, git/PR boundaries,
directory boundaries), the canonical source is the **root
[`AGENTS.md`](../AGENTS.md)**. If anything here conflicts with the root file,
the root file wins — except for the copy-protection warning above, which is
Pro-specific and always applies.

For Claude-oriented tool tips and Pro architecture notes, see
[`CLAUDE.md`](./CLAUDE.md) in this directory.

These instructions guide AI agent behavior. They do not replace or modify the
React on Rails Pro license, EULA, or any other legal terms.

## License header enforcement

`script/check-pro-license-headers` (at the repo root) verifies that every
in-scope Pro file carries the proprietary header.

- Check: `script/check-pro-license-headers`
- Insert/upgrade headers in place: `script/check-pro-license-headers --fix`
- See which files are in scope: `script/check-pro-license-headers --list`

Scope, header text, and rationale are documented in
[`internal/planning/2026-06-08-pro-license-header-enforcement-design.md`](../internal/planning/2026-06-08-pro-license-header-enforcement-design.md).
When you add a new Pro source file, run `--fix` (or let the pre-commit hook do
it) so the header is present before you commit.
