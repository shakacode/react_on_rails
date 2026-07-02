---
name: react-on-rails-update-changelog
description: React on Rails release-train changelog updates, including target=release and release/X.Y.Z PR targeting while the portable update-changelog skill remains mainline-only.
argument-hint: '[classification-sweep BASE_REF..TARGET_REF|release|rc|beta|version] [target=main|release|release/X.Y.Z]'
---

# React on Rails Update Changelog

Use this repo-local skill only when React on Rails release-train targeting matters:

- the user passes `target=release` or `target=release/X.Y.Z`
- the current branch is `release/X.Y.Z`
- an RC/final promotion workflow needs the changelog PR to target `release/X.Y.Z`
- the user asks for React on Rails release-train changelog handling

For ordinary mainline changelog entries on `main`, use the installed/shared
`$update-changelog` skill. This repo-local skill exists under a distinct name so
Codex does not show a duplicate `update-changelog` picker entry.

## Required Context

Before editing, read:

1. `AGENTS.md` changelog and release-train sections.
2. `internal/contributor-info/release-train-runbook.md` when the target is a
   `release/*` branch.
3. `.agents/agent-workflow.yml` for `base_branch`, `changelog`, and changelog
   policy values.

Resolve the shared helper directory explicitly; do not assume this checkout has
a repo-local shared skill copy:

```bash
UPDATE_CHANGELOG_SKILL_DIR="${UPDATE_CHANGELOG_SKILL_DIR:-$(.agents/bin/shared-skill-dir update-changelog)}"
```

Use that helper for mechanical classification sweeps:

```bash
BASE_REF="${BASE_REF:?set BASE_REF, e.g. v17.0.0.rc.2}"
TARGET_REF="${TARGET_REF:?set TARGET_REF, e.g. origin/main or origin/release/17.0.0}"
"${UPDATE_CHANGELOG_SKILL_DIR}/bin/changelog-merged-prs" "${BASE_REF}..${TARGET_REF}"
```

## Target Resolution

Resolve the target before writing, stamping, branching, or creating a PR:

- `target=main`: use the installed/shared `$update-changelog` flow against the
  configured base branch.
- `target=release/X.Y.Z`: verify `origin/release/X.Y.Z` exists and target that
  branch.
- `target=release`: use the current `release/X.Y.Z` branch when already on one;
  otherwise list `origin/release/*`. If exactly one active release branch exists,
  target it. If more than one exists, ask which branch to use.
- No `target=` while on `release/X.Y.Z`: target the current release branch.
- No `target=` while on `main` and exactly one active `origin/release/*` branch
  exists: ask whether this changelog update should target `release/X.Y.Z` or
  `main`. Default to `main` only when the user does not choose a release target.
- No active release branch: default to `main`.

If a requested release target does not exist on `origin`, stop and report:

```text
target=release requested but no matching origin/release/X.Y.Z branch exists.
Start the release line first, or use target=main.
```

## Release-Branch Procedure

For a resolved `release/X.Y.Z` target:

1. Fetch current release state:

   ```bash
   git fetch --prune origin main '+refs/heads/release/*:refs/remotes/origin/release/*'
   ```

2. Require a clean worktree before changing branches or writing changelog
   entries.
3. Create a feature branch from the release branch tip, not from `main`:

   ```bash
   git switch -c "changelog-<version-or-mode>" "origin/release/X.Y.Z"
   ```

4. Add or curate entries in `CHANGELOG.md` under `### [Unreleased]`, using the
   classification taxonomy and entry format from `AGENTS.md`.
5. Run the repo's version-stamping task when requested:

   ```bash
   bundle exec rake "update_changelog[rc]"
   bundle exec rake "update_changelog[release]"
   bundle exec rake "update_changelog[beta]"
   bundle exec rake "update_changelog[17.0.0.rc.1]"
   ```

6. Keep compare-link anchoring consistent with the repo task. Release-target
   entries intentionally keep the `[unreleased]` comparison anchored to `main`
   because release-branch entries are forward-ported to `main`.
7. Commit only the changelog files, push the feature branch, and open the PR
   against the release branch:

   ```bash
   git add CHANGELOG.md
   git commit -m "Update changelog for <version-or-mode>"
   git push -u origin "$(git branch --show-current)"
   gh pr create --draft --base "release/X.Y.Z" --head "$(git branch --show-current)"
   ```

8. After the PR merges into `release/X.Y.Z`, follow the release-train runbook to
   forward-port the changelog result to `main` when required.

Do not recreate `.agents/skills/update-changelog/SKILL.md` in this repo unless a
maintainer explicitly chooses to restore a same-name local override and accepts
the duplicate skill picker entry. Keep same-name shared workflow skills in the
installed shared pack.
