---
name: update-changelog
description: Analyze merged PRs and update the changelog, optionally stamping release, rc, beta, or explicit version headers, targeting either main or an active release/X.Y.Z branch. Use before releases or when changelog entries are missing.
argument-hint: '[classification-sweep BASE_REF..TARGET_REF|release|rc|beta|version] [target=main|release|release/X.Y.Z]'
---

# Update Changelog

You are helping to add an entry to the repo's changelog (see `AGENTS.md` → **Agent Workflow Configuration**).

## Arguments

This skill accepts an optional mode argument from the invocation text:

- **No argument** (`/update-changelog`): Add entries to `[Unreleased]` without stamping a version header. Use this during development.
- **`release`** (`/update-changelog release`): Add entries and stamp a version header. Auto-compute the next version based on changes (breaking -> major, added features -> minor, fixes -> patch). Then the repo's release task (with no args) will pick up this version automatically.
- **`rc`** (`/update-changelog rc`): Same as `release`, but stamps an RC prerelease version (e.g., `16.5.0.rc.0`). Auto-increments the RC index if prior RCs exist for the same base version.
- **`beta`** (`/update-changelog beta`): Same as `rc`, but stamps a beta prerelease version (e.g., `16.5.0.beta.0`).
- **`classification-sweep`** (`/update-changelog classification-sweep BASE_REF..TARGET_REF`): Print a mechanical review table for every merged PR in the selected range before deciding which changelog entries to add. This read-only agent workflow runs git and GitHub API commands directly; it does not edit the changelog and does not invoke any header-stamping task.
- **Explicit version** (`/update-changelog 16.5.0.rc.10`): Add entries and stamp the exact version provided. Skips auto-computation — use this when you already know the target version. The version string must look like a semver version (with optional `.rc.N` or `.beta.N` suffix).

This skill also accepts an optional **target** keyword that decides which branch the entries land on and which branch the PR targets:

- **`target=main`** (default): Entries go to `[Unreleased]`, the feature branch is cut from the base branch, and the PR targets the base branch. This is the historical behavior and is unchanged.
- **`target=release`** or **`target=release/X.Y.Z`**: Entries land on the active release line. The feature branch is cut from `release/X.Y.Z`, the PR targets `release/X.Y.Z` (`gh pr create --base release/X.Y.Z`), and any version stamp goes under the in-progress rc section on that branch. Use this during rc stabilization, when a fix that merged into `release/X.Y.Z` needs its changelog entry on the release line rather than on the base branch.

See **Target: release or main?** below for how the target is resolved (including the prompt that fires when an active release line is detected).

## Target: release or main?

The changelog can be updated against two different branch targets. **Resolve the target before writing or stamping anything** — it determines the branch you cut, the `--base` of the PR, and where entries land.

The two targets:

- **`main` target (default).** Entries accumulate under `### [Unreleased]`, the feature branch is cut from `origin/<BASE_BRANCH>`, and the PR targets the base branch. During a stable development cycle this is the only target, and the skill must not prompt.
- **`release` target.** During rc stabilization the repo runs an ephemeral `release/X.Y.Z` branch (one per final target, deleted after the final ships; see `AGENTS.md` → **Release-Train Branching And Phase Gating** and `internal/contributor-info/release-train-runbook.md`). A stabilizing fix merges into `release/X.Y.Z`, so its changelog entry belongs on that branch — under the in-progress rc section — not on the base branch. Cut the feature branch from `release/X.Y.Z` and open the PR with `gh pr create --base release/X.Y.Z`.

### Detecting an active release line

Run these read-only checks (resolve `BASE_BRANCH` from `AGENTS.md` → **Agent Workflow Configuration** first):

```bash
git fetch --prune origin
# Release lines are ephemeral release/X.Y.Z branches (X.Y.Z = final target, no -rc suffix).
git branch -r --list 'origin/release/*' | sed 's#^[[:space:]]*origin/##'
```

The agent-coordination backend also publishes the active phase per line; when it is available (`agent-coord doctor --json` healthy, then a targeted `agent-coord status … --json` that exits 0), an `rc`/`final` phase for a `release/*` target confirms the release line is live. Treat the backend as advisory here — the `release/*` branch list is the authoritative signal for this skill.

### Choosing the target

1. **Explicit `target=` argument wins.** `target=release/X.Y.Z` selects that exact branch (verify it exists on `origin`; abort with a clear message if not). `target=release` with no version resolves the lone active `release/*` branch (abort and ask which one if more than one exists). `target=main` forces the main target with no prompt. If an explicit `target=release` (or `target=release/X.Y.Z`) is requested but **no matching `release/*` branch exists on `origin`**, do not silently fall back to `main` — stop and report, for example: `target=release requested but no release/* branch exists. Start one with `rake "release:start[X.Y.Z]"` (see the release-train runbook), then retry; or use target=main to land on [Unreleased].`
2. **No `target=` argument, no active `release/*` branch:** default to `main` **without prompting**. This keeps the common development path frictionless.
3. **No `target=` argument, exactly one active `release/*` branch:** **ask the user "release or main?"** — this is the core decision. Present the detected branch, for example:

   ```text
   An active release line was detected: release/17.0.0.
   Should this changelog update target the release line or main?
     - release: entry lands on release/17.0.0 (PR --base release/17.0.0), under the in-progress rc section
     - main:    entry lands on [Unreleased] (PR --base <BASE_BRANCH>)  [default]
   ```

   Wait for the answer before writing entries, stamping a version, or creating a branch.

4. **No `target=` argument, multiple active `release/*` branches:** list them and ask which release line (or `main`) to target; do not guess.

Once the target is `main`, follow the rest of this document exactly as written — nothing else changes. Once the target is `release`, apply the **Release-target adjustments** below: they change the fetch/compare/branch base and the PR base (substituting `release/X.Y.Z` for the base branch); the changelog mechanics themselves — classification, entry formatting, version-stamping, and curation — are unchanged.

### Release-target adjustments

When the resolved target is a `release/X.Y.Z` branch, only these things change relative to the `main` target:

- **Base for fetch/compare and branch creation.** Read and branch from `release/X.Y.Z` instead of the base branch: `git fetch origin release/X.Y.Z`, then cut the feature branch from `origin/release/X.Y.Z`.
- **Where entries land.** Entries still go under `### [Unreleased]` while you edit; when you stamp the rc header, the version-stamping task moves the `[Unreleased]` entries under the new rc header (it inserts the header right after `### [Unreleased]`). This is the same mechanism as the `main`-target rc flow — only the branch differs. Typically the release target is used with `rc` (or an explicit `X.Y.Z.rc.N`); a bare `release`/stable stamp on a `release/*` branch is the promotion case handled by the release task, not this skill.
- **PR base.** Open the PR against the release branch: `gh pr create --base release/X.Y.Z`.
- **Compare links — keep `…main` anchoring (do NOT change the base).** The bottom-of-file compare links (and the `[unreleased]` link) are written by the repo's version-stamping task, which anchors `[unreleased]` at `…main`. **Leave that anchoring as-is for release-target entries.** Rationale: (1) every `release/*` entry is forward-ported into the base branch's `[Unreleased]` anyway (`git cherry-pick -x`, per the runbook), so `…main` is where these entries ultimately live; (2) the `release/X.Y.Z` branch is ephemeral and deleted after the final ships — its transient `[unreleased]` link is not a durable artifact, the tags and the base-branch changelog are; (3) it keeps the version-stamping task untouched, avoiding any change to the parsing/link helpers shared with the forward-port reconciliation flow. So the rc compare link the task adds (e.g. `[17.0.0.rc.1]: …/compare/v17.0.0.rc.0...v17.0.0.rc.1`) is correct as-emitted, and `[unreleased]: …compare/v17.0.0.rc.1...main` is intentionally left pointing at `main`. Do not introduce a release-branch base anchor.

## When to Use This

This skill serves four use cases at different points in the release lifecycle:

**During development** -- Add entries to `[Unreleased]` as PRs merge:

- Run `/update-changelog` to find merged PRs missing from the changelog
- Entries accumulate under `### [Unreleased]`

**Before each RC/release changelog edit** -- Sweep classifications mechanically:

- Run `/update-changelog classification-sweep BASE_REF..TARGET_REF` before adding entries or stamping a version
- Print a full table for every merged PR in the selected range, including `no-entry` rows, so reviewers can spot missed classifications
- Use the table to decide which `entry-needed` rows become changelog entries

**Before a release** -- Stamp a version header and prepare for release:

- Run `/update-changelog release` (or `rc`, `beta`, or an explicit version like `16.5.0.rc.10`) to add entries AND stamp the version header
- The version is auto-computed from changes (breaking -> major, features -> minor, fixes -> patch) — skipped when an explicit version is provided
- The skill automatically commits, pushes, and opens a PR — review and merge it
- Then run the repo's release task (no args needed -- it reads the version from the changelog)
- The release task automatically creates a GitHub release from the changelog section

**After a release you forgot to update the changelog for** -- Catch-up mode:

- The skill can retroactively find commits between tags and add missing entries
- Ask the user whether to stamp a version header or add to `[Unreleased]`

### Why changelog comes BEFORE the release

- The repo's release task automatically creates a GitHub release if a changelog section exists -- no separate sync-GitHub-release step needed
- The release task warns if no changelog section is found for the target version
- A premature version header (if release fails) is harmless -- you'll release eventually
- A missing changelog after release means the GitHub release must be created manually

## Auto-Computing the Next Version

When stamping a version header (`release`, `rc`, or `beta`), compute the next version as follows:

1. **Find the latest stable version tag** using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
   ```

2. **Determine bump type from changelog content**:
   - If changes include `#### Breaking Changes` or `#### ⚠️ Breaking Changes` -> **major** bump
   - If changes include `#### Added`, `#### New Features`, `#### Features`, or `#### Enhancements` -> **minor** bump
   - If changes only include `#### Fixed`, `#### Security`, `#### Improved`, `#### Changed`, `#### Deprecated`, or `#### Removed` -> **patch** bump

3. **Compute the version**:
   - For `release`: Apply the bump to the latest stable tag (e.g., `16.4.0` + minor -> `16.5.0`)
   - For `rc`: Apply the bump, then find the next RC index based **only on git tags** (e.g., if `v16.5.0.rc.0` tag exists -> `16.5.0.rc.1`). **Do NOT use changelog headers** to determine the next index — a version header in the changelog is a draft that may not have been released yet. Only git tags represent shipped versions.
   - For `beta`: Same as RC but with beta suffix

4. **Verify**: Check that the computed version is newer than ALL existing tags (stable and prerelease). If not, ask the user what to do.

5. **Show the computed version to the user and ask for confirmation** before stamping the header. If the bump type is ambiguous (e.g., changes could reasonably be classified as patch vs minor, or the changelog headings don't clearly signal the bump level), explain your reasoning for the suggested bump and ask the user to confirm or override before proceeding.

## Critical Requirements

1. **User-visible changes only**: Only add changelog entries for user-visible changes:
   - New features
   - Bug fixes
   - Breaking changes
   - Deprecations
   - Performance improvements
   - Security fixes
   - Changes to public APIs or configuration options

2. **Do NOT add entries for**:
   - Linting fixes
   - Code formatting
   - Internal refactoring
   - Test updates
   - Documentation fixes (unless they fix incorrect docs about behavior)
   - CI/CD changes

## Classification Sweep Mode

Use `classification-sweep` before every RC/release changelog edit, and whenever a prior changelog pass might have missed a merged PR. This is a mechanical coverage pass: it classifies every merged PR in the selected range, then humans review the classifications before entries are written.

### Exact PR-Listing Command

Set `BASE_REF` to the previous release tag or lower bound and `TARGET_REF` to the release tag, the configured base branch from `AGENTS.md`, or another upper bound being audited. Then run the committed `changelog-merged-prs` helper to list merged PRs in first-parent order. It extracts PR numbers from squash titles (the `(#NNNN)` suffix) and `Merge pull request #NNNN` subjects, falls back to GitHub's commit-to-PR API for commits that lack an inline PR number, dedups by PR number, and emits an explicit `UNKNOWN` row for any commit that still cannot be mapped.

```bash
BASE_REF="${BASE_REF:?set BASE_REF, e.g. v17.0.0.rc.1}"
BASE_BRANCH="${BASE_BRANCH:?set BASE_BRANCH from AGENTS.md -> Agent Workflow Configuration}"
TARGET_REF="${TARGET_REF:?set TARGET_REF, e.g. v17.0.0.rc.2 or origin/${BASE_BRANCH}}"
UPDATE_CHANGELOG_SKILL_DIR="${UPDATE_CHANGELOG_SKILL_DIR:-.agents/skills/update-changelog}"

# JSON array of {pr, sha, subject}; pr is an integer, or the string "UNKNOWN".
"${UPDATE_CHANGELOG_SKILL_DIR}/bin/changelog-merged-prs" "${BASE_REF}..${TARGET_REF}"

# Or --text for pr<TAB>sha<TAB>subject rows (UNKNOWN in the pr column):
"${UPDATE_CHANGELOG_SKILL_DIR}/bin/changelog-merged-prs" "${BASE_REF}..${TARGET_REF}" --text
```

The helper defaults the repo to `gh repo view`; pass `--repo OWNER/REPO` to override. Run `changelog-merged-prs --help` for the full output contract and `--self-check` to validate the parser and a read-only `gh` smoke test. Each row is a merged PR for the range; rows with `"pr": "UNKNOWN"` are commits that could not be mapped to a merged PR on the default branch.

If any commit in the range cannot be mapped to a PR, the helper prints an explicit `UNKNOWN` row for that commit. Carry that row into the full table with `Result` set to `UNKNOWN`, investigate it, and do not finish the sweep until the row is resolved to a merged PR classification or explicitly reported as a blocker. Do not silently drop it.

A sudden spike of `UNKNOWN` rows can indicate stale GitHub authentication, API rate limits, or a temporary API failure rather than genuinely unmapped commits. Run `gh auth status` and rerun the helper when the UNKNOWN count looks suspicious.

The fallback makes one GitHub API call per commit whose subject lacks `(#NNNN)`. Typical RC ranges complete quickly, but large ranges with many direct commits can hit rate limits. Direct version-bump commits, bot commits, and release-automation commits may be expected `UNKNOWN` rows; keep them in the table with `Result` set to `UNKNOWN`, choose `internal` or `release-process`, and explain that no PR-backed changelog entry exists.

### Required Sweep Output

Print the full Markdown table. No silent caps, no "top N", and no filtering to only likely changelog entries. Every row from the helper must appear, including `no-entry` rows.

```markdown
| PR    | Title                                  | Result       | Category         | Reason                                                                                         |
| ----- | -------------------------------------- | ------------ | ---------------- | ---------------------------------------------------------------------------------------------- |
| #3595 | Async manifest signature verification  | entry-needed | perf-reliability | Moves manifest signature checks async, removing blocking filesystem work from the render path. |
| #3597 | Document release-gate tracker workflow | no-entry     | release-process  | Defines release-gate tracking docs; no product behavior changes.                               |
```

Allowed `Result` values for mapped PRs are exactly:

- `entry-needed`
- `no-entry`

Use `UNKNOWN` only for unmapped commit rows emitted by the helper; resolve or report those rows before finishing.

Allowed `Category` values are repo-specific: use exactly those defined in the repo's
changelog classification taxonomy (see `AGENTS.md` → **Changelog**). Copy them exactly as
listed there, including spaces, hyphens, and casing.

Each row needs a one-line reason specific enough for review. Avoid generic reasons like "not user-visible" unless the row also says why.

### Classification Rubric

- Use `entry-needed` for user-visible product behavior: public API/config/generator changes, runtime bug fixes, compatibility changes, breaking changes, security fixes, and performance or reliability changes users would care about.
- Use `entry-needed` for scope-specific runtime changes (for example a commercial/Pro tier) that affect users of that scope — observable runtime behavior, compatibility, generated config, or logging/error changes. A scope-only change is still user-visible to users of that scope.
- Use `entry-needed` for `perf-reliability` when the PR changes runtime performance, removes blocking work, improves production recovery, or makes user-visible failures diagnosable. For example, a PR that moves manifest signature checks from synchronous filesystem calls to async checks is `entry-needed`.
- Use `no-entry` for docs-only, tests-only, formatting, lint, internal refactors, CI, benchmark harnesses, release automation, agent/process docs, and other contributor-only changes. Keep docs-only PRs as `entry-needed` when they correct incorrect public behavior documentation; classify those by the public surface they document, per the repo's taxonomy.
- Categorize by the primary surface changed, not by the changelog section it might eventually use, using the category definitions in the repo's changelog classification taxonomy (`AGENTS.md` → **Changelog**). A performance/reliability category, where the repo defines one, applies regardless of result: use `entry-needed` when the change directly benefits users at runtime (such as removing blocking work from the render path) and `no-entry` for internal benchmark harnesses or regression tooling.

### Reverts and Re-Runs

When a revert lands in the selected RC/release window, re-run the sweep or revisit affected classifications and changelog entries before stamping. Reverts can invalidate earlier `entry-needed` rows or require the original entry to be rewritten. For example, if a revert like #3860 lands after #3587, revisit the #3587 classification and changelog entry instead of carrying the original entry forward unchanged.

## Formatting Requirements

### Entry Format

Each changelog entry MUST follow the repo's exact entry format (the PR-and-author link format defined by the repo's changelog; see `AGENTS.md` → **Agent Workflow Configuration**). Match the existing entries in the changelog and follow these portable structural rules:

- Start with a dash followed by a space
- Use **bold** for the main description
- End the bold description with a period before the link
- Always link to the PR using the repo's PR-link format — **NO hash symbol** before the PR number
- Always link to the author
- End with a period after the author link
- Additional details can be added after the main entry, using proper indentation for multi-line entries

### Breaking Changes Format

For breaking changes, lead the bold description, note the migration guide, append the repo's PR-and-author link, then the guide:

```markdown
- **Feature Name**: Description of the breaking change. See migration guide below. <repo PR-and-author link, per the changelog format above>

**Migration Guide:**

1. Step one
2. Step two
```

### Category Organization

Entries should be organized under these section headings **in the following order** (most critical first):

**Preferred section order:**

1. `#### Breaking Changes` - Breaking changes with migration guides (FIRST - most critical for upgrading users)
2. `#### Added` - New features
3. `#### Changed` - Changes to existing functionality
4. `#### Improved` - Improvements to existing features
5. `#### Fixed` - Bug fixes
6. `#### Deprecated` - Deprecation notices
7. `#### Removed` - Removed features
8. `#### Security` - Security-related changes

**Rationale:** Breaking changes come first because they are the most critical information for anyone upgrading. Users need to know immediately if their code will break before seeing what new features are available.

**Additional custom headings** (use sparingly when standard headings don't fit):

- `#### Documentation` - Documentation improvements
- `#### Developer (Contributors Only)` - Internal tooling changes
- `#### API Improvements` - API changes and improvements
- `#### Generator Improvements` - Generator-specific changes
- `#### Performance` - Performance improvements

**Prefer standard headings.** Only use custom headings when the change needs more specific categorization.

**Tagged entries**: When the repo's changelog defines an inline scope tag (such as a `**[Pro]**` prefix; see `AGENTS.md` → **Agent Workflow Configuration**), apply it within the standard category sections (e.g., `- **[Pro]** **Feature name**: Description...`). Do NOT create separate per-tag subsections.

**Only include section headings that have entries.**

### Version Stamping with the Repo's Changelog Task

When this command is invoked with `release`, `rc`, `beta`, or an explicit version (e.g., `16.5.0.rc.10`), **use the repo's changelog version-stamping task** (the changelog header/diff-link stamping task documented in `AGENTS.md` → **Agent Workflow Configuration**) to stamp the version header after adding entries, passing the mode (`release`, `rc`, or `beta`) or an explicit version.

The version-stamping task handles:

- Auto-computing the next version from git tags (prerelease index is determined solely from tags, not changelog headers)
- Inserting the version header right after `### [Unreleased]`
- Updating version diff links at the bottom of the file
- For `release` mode: collapsing prior `rc`/`beta` sections of the same base version into the new stable section (rc/beta modes leave prior prerelease sections intact so users can see what changed between RCs)

Do NOT manually insert version headers or update diff links -- the version-stamping task does this correctly.

**When to use which tool:**

- **`/update-changelog release`**: Full automation -- analyzes commits, writes changelog entries, then calls the version-stamping task to stamp the version header. Use before a release.
- **`/update-changelog` (no args)**: Adds entries to `[Unreleased]` during development. Does not stamp a version header.
- **The repo's changelog version-stamping task directly**: Header-only stamping for users who want to write entries manually.

### Finding the Most Recent Version

To determine the most recent version:

1. **Check git tags** to find the latest released version:

   ```bash
   git tag --sort=-v:refname | head -10
   ```

   This shows tags like `v16.2.0.beta.20`, `v16.2.0.beta.19`, etc.

2. **Check the changelog** for version headers (note: changelog uses versions WITHOUT the `v` prefix):
   - `### [16.2.0.beta.19] - 2025-12-10` (beta version)
   - `### [16.1.1] - 2025-09-24` (stable version)

3. **Use this regex pattern** to find version headers in the changelog:

   ```regex
   ^### \[([^\]]+)\] - \d{4}-\d{2}-\d{2}
   ```

4. **The first match after `### [Unreleased]`** is the most recent version in the changelog.

**IMPORTANT**: Git tags use `v` prefix (e.g., `v16.2.0.beta.20`). Changelog **headers** use versions WITHOUT the `v` prefix (e.g., `### [16.2.0.beta.20]`), but compare **links** at the bottom of the file MUST use the `v` prefix to match the git tag (e.g., `.../compare/v16.1.1...v16.2.0.beta.20`). Strip the `v` only for changelog headers, not for compare link URLs.

### Version Links

After adding an entry to the `### [Unreleased]` section, ensure the version diff links at the bottom of the file are correct.

The format at the bottom should be:

```markdown
[unreleased]: https://github.com/<owner>/<repo>/compare/v16.2.0.beta.19...main
[16.2.0.beta.19]: https://github.com/<owner>/<repo>/compare/v16.1.1...v16.2.0.beta.19
```

Replace `main` with the base branch value from `AGENTS.md` → **Agent Workflow Configuration** when the repo uses a different base branch.

When a new version is released:

1. Insert the new version header **immediately after** `### [Unreleased]`:

   ```markdown
   ### [Unreleased]

   ### [16.2.0.beta.20] - 2025-12-12
   ```

2. Update the `[unreleased]:` link to compare from the new version to main
3. Add a new version link comparing the previous version to the new version

## Process

### For Regular Changelog Updates

#### Step 1: Fetch and read current state

- First resolve the **target** (see **Target: release or main?**). For the `main` target use the base branch below. For the `release` target, substitute the resolved `release/X.Y.Z` for `BASE_BRANCH` **throughout the Process section** (here in Step 1 and in Step 3's `git log` / comparison commands), so fetches and post-tag commit scans run against the release line rather than the base branch.
- Resolve `BASE_BRANCH` from `AGENTS.md` -> **Agent Workflow Configuration**, then run `git fetch origin "${BASE_BRANCH}"` to ensure you have the latest commits
- After fetching, use `origin/${BASE_BRANCH}` for all comparisons, not the local base branch
- Read the current changelog to understand the existing structure

#### Step 2: Reconcile tags with changelog sections (DO THIS FIRST)

**This step catches missing version sections and is the #1 source of errors when skipped.**

1. Get the latest git tag: `git tag --sort=-v:refname | head -5`
2. Get the most recent version header in the changelog (the first `### [VERSION] - DATE` after `### [Unreleased]`)
3. **Compare them.** If the latest git tag (minus the `v` prefix) does NOT appear anywhere in the changelog version headers, there are tagged releases missing from the changelog. **Important**: Don't just compare against the _top_ changelog header — a version header may exist _above_ the latest tag if it was stamped as a draft before tagging. Check whether the tag's version appears in _any_ `### [X.Y.Z]` header. For example:
   - Latest tag: `v16.4.0.rc.4`, and no `### [16.4.0.rc.4]` header exists anywhere in the changelog
   - **Result: `16.4.0.rc.4` is missing and needs its own section**
   - But if `### [16.5.0.rc.0]` is the top header (a draft, not yet tagged) and `### [16.4.0.rc.4]` exists below it, then nothing is missing — the top header is simply a pre-release draft

4. For EACH missing tagged version (there may be multiple):
   a. Find commits in that tag vs the previous tag: `git log --oneline PREV_TAG..MISSING_TAG`
   b. Extract PR numbers and fetch details for user-visible changes
   c. Check which entries currently in `### [Unreleased]` actually belong to this tagged version (compare PR numbers against the commit list)
   d. **Create a new version section** immediately before the previous version section:

   ```markdown
   ### [16.4.0.rc.4] - 2026-02-22
   ```

   e. **Move** matching entries from Unreleased into the new section
   f. **Add** any new entries for PRs in that tag that aren't in the changelog at all
   g. **Update version diff links** at the bottom of the file:
   - Update `[unreleased]:` to compare from the newest tag to main
   - Add a link for each new version section

5. Get the tag date with: `git log -1 --format="%Y-%m-%d" TAG_NAME`

#### Step 3: Add new entries for post-tag commits

> For the `release` target, substitute the resolved `release/X.Y.Z` for `BASE_BRANCH` in the commands below (see Step 1), so the post-tag commit scan runs against the release line.

1. Resolve `BASE_BRANCH` from `AGENTS.md` -> **Agent Workflow Configuration**, then run `git log --oneline "LATEST_TAG..origin/${BASE_BRANCH}"` to find commits after the latest tag (LATEST_TAG is the most recent git tag, i.e., the same one identified in Step 2)
2. Extract PR numbers: `git log --oneline "LATEST_TAG..origin/${BASE_BRANCH}" | grep -oE "#[0-9]+" | sort -u`
3. If Step 2 found no missing tagged versions, verify no tag is ahead of the base branch: `git log --oneline "origin/${BASE_BRANCH}..LATEST_TAG"` should be empty. If not, entries in "Unreleased" may belong to that tagged version — Step 2 should have caught this, so re-check.
4. For each PR number, check if it's already in the changelog: `CHANGELOG_PATH="${CHANGELOG_PATH:?set CHANGELOG_PATH from AGENTS.md -> Agent Workflow Configuration}"; grep "PR ${PR_NUMBER:?set PR_NUMBER}" "${CHANGELOG_PATH}"`
5. For PRs not yet in the changelog:
   - Get PR details: `gh pr view NUMBER --json title,body,author` (add `--repo OWNER/REPO` when not in the repo)
   - **Never ask the user for PR details** - get them from git history or the GitHub API
   - Validate that the change is user-visible (per the criteria above). Skip CI, lint, refactoring, test-only changes.
   - Add the entry to `### [Unreleased]` under the appropriate category heading

#### Step 4: Stamp version header (only when a version mode or explicit version is given)

If the user passed `release`, `rc`, `beta`, or an explicit version string as an argument:

**For `release`, `rc`, or `beta` keywords:**

1. Run the repo's changelog version-stamping task with the matching mode (`release`, `rc`, or `beta`) to stamp the version header.

2. The version-stamping task will:
   - Auto-compute the next version
   - Insert the header after `### [Unreleased]`
   - Update diff links at the bottom
   - For `release`: collapse prior `rc`/`beta` sections of the same base version into the new stable section
   - For `rc`/`beta`: leave prior prerelease sections intact (each prerelease keeps its own section so users on an earlier RC can see what changed)

3. **Verify** the computed version looks correct. If not, the user can manually adjust.

**For an explicit version string** (e.g., `16.5.0.rc.10`):

1. Pass the explicit version directly to the repo's changelog version-stamping task.

2. **Verify** the stamped header and diff links match the requested version.

If no argument was passed, skip this step -- entries stay in `### [Unreleased]`.

#### Step 5: Verify and finalize

1. **Verify formatting**:
   - Bold description with period
   - Proper PR link (NO hash symbol)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character
   - **No duplicate section headings** (e.g., don't create two `#### Fixed` sections — merge entries into the existing heading)
2. **Verify version sections are in order** (Unreleased -> newest tag -> older tags)
3. **Verify version diff links** at the bottom of the file are correct (compare links MUST use the `v` prefix to match git tags)
4. **Show the user** a summary of what was done:
   - Which version sections were created
   - Which entries were moved from Unreleased
   - Which new entries were added
   - Which PRs were skipped (and why)
5. If in `release`/`rc`/`beta` mode or explicit-version mode, **automatically commit, push, and open a PR**. The branch you start from and the PR base depend on the resolved target (see **Target: release or main?**). Let `INTEGRATION_BRANCH` be the base branch from `AGENTS.md` for the `main` target, or `release/X.Y.Z` for the `release` target:
   - Verify the working tree only has changelog changes; if there are other uncommitted changes, warn the user and stop
   - Verify the current branch is `INTEGRATION_BRANCH` (`git branch --show-current`); if not, warn the user and stop. For the `main` target `INTEGRATION_BRANCH` is the base branch (today's behavior); for the `release` target it is the resolved `release/X.Y.Z`, so finalizing while checked out on that release branch is expected and allowed.
   - Create a feature branch off `INTEGRATION_BRANCH` (e.g., `changelog-16.4.0.rc.10`)
   - Stage only the changelog after resolving the repo's changelog path from `AGENTS.md`: set `CHANGELOG_PATH="${CHANGELOG_PATH:?set CHANGELOG_PATH from AGENTS.md}"`, run `git add "${CHANGELOG_PATH}"`, and commit with message `Update changelog for VERSION` (using the stamped version)
   - Push and open a PR with the changelog diff as the body, targeting `INTEGRATION_BRANCH`. For the `main` target this is the default base; for the `release` target pass it explicitly: `gh pr create --base release/X.Y.Z`
   - If the push or PR creation fails, the changelog is already stamped locally — fix the issue (e.g., authentication, branch protection), then run `git push -u origin <branch>` and `gh pr create --base "$INTEGRATION_BRANCH"` manually
   - Remind the user to run the repo's release task (no args) after merge to publish and auto-create the GitHub release. For the `release` target, that release task runs from the `release/X.Y.Z` branch to cut the rc tag (see the release-train runbook); the forward-port step later re-homes the entry into the base branch's `[Unreleased]`.

### For Prerelease Versions (RC and Beta)

When the user passes `rc` or `beta` as an argument:

1. **Find the latest tag** (stable or prerelease) using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | head -10
   ```

2. **Auto-compute the next prerelease version** using the process in "Auto-Computing the Next Version" above.

3. **Do NOT collapse prior prereleases.** Each RC/beta is a separately-tagged release that users install — they need to see what changed between, for example, `rc.0` and `rc.1` (especially when diagnosing a regression in a specific RC). Each run of the repo's release task reads only the top-most `### [VERSION]` section, so as long as each RC has its own section, the corresponding GitHub release gets its own focused notes. Instead:
   - Insert the new prerelease version section immediately after `### [Unreleased]`, **above** any prior prerelease sections (preserves newest-first ordering)
   - Any entries already under `### [Unreleased]` belong to this prerelease — the version-stamping task moves them under the new header automatically when it inserts the version line right after `### [Unreleased]`
   - Leave prior prerelease sections (e.g., `### [16.5.0.rc.0]`) untouched — keep their entries and their compare links at the bottom of the file
   - Add any new user-visible changes from commits since the last prerelease tag to the new section only
   - Add a new compare link at the bottom comparing the previous prerelease tag (or the last stable tag if this is the first RC) to the new prerelease tag
   - Update the `[unreleased]:` compare link to point from the new prerelease tag to `main`

**Resulting structure** after stamping `16.5.0.rc.1` (with `16.5.0.rc.0` already shipped on top of stable `16.4.0`):

```markdown
### [Unreleased]

### [16.5.0.rc.1] - 2026-03-15

#### Fixed

- **Fix regression introduced in rc.0**. [PR 2500](https://github.com/<owner>/<repo>/pull/2500) by [username](https://github.com/username).

### [16.5.0.rc.0] - 2026-03-01

#### Added

- **New feature**. [PR 2490](https://github.com/<owner>/<repo>/pull/2490) by [username](https://github.com/username).

### [16.4.0] - 2026-02-15

...

[unreleased]: https://github.com/<owner>/<repo>/compare/v16.5.0.rc.1...main
[16.5.0.rc.1]: https://github.com/<owner>/<repo>/compare/v16.5.0.rc.0...v16.5.0.rc.1
[16.5.0.rc.0]: https://github.com/<owner>/<repo>/compare/v16.4.0...v16.5.0.rc.0
[16.4.0]: https://github.com/<owner>/<repo>/compare/v16.3.0...v16.4.0
```

Both RC sections remain intact with their own compare links until the stable release coalesces them. **Coalescing happens only at the stable release** — see "For Prerelease to Stable Version Release" below.

**Note**: The new version header must be inserted **immediately after `### [Unreleased]`** (see Step 4). This ensures correct newest-first ordering of version headers.

### For Prerelease to Stable Version Release

When releasing from prerelease to a stable version (e.g., `v16.5.0.rc.1` -> `v16.5.0`), this is where the accumulated prerelease sections get coalesced into one stable section. **Curate carefully** — users landing on the stable version don't care about intermediate prerelease state, and noise here makes the upgrade story harder to read.

#### Step 1: Coalesce all prerelease sections into one stable section

- Replace `### [16.5.0.rc.0]`, `### [16.5.0.rc.1]`, `### [16.5.0.beta.1]`, etc. (however many exist) with a single `### [16.5.0] - YYYY-MM-DD` section
- **Move any remaining entries from `### [Unreleased]` into the new stable section** — anything still under `[Unreleased]` at stable-release time is shipping in this stable version. Leave `### [Unreleased]` with only its header (no entries).
- Combine entries from all prerelease sections and the moved `[Unreleased]` entries, consolidating duplicate category headings (e.g., merge multiple `#### Fixed` sections into one under the preferred order from "Category Organization")
- Remove the orphaned compare links at the bottom of the file for the coalesced prerelease versions
- Add the `[16.5.0]` compare link pointing from the **previous stable tag** (e.g., `v16.4.0`) to `v16.5.0` — **not** from the latest RC tag
- Update the `[unreleased]:` compare link to point from `v16.5.0` to `main`
- **Before committing**, spot-check the compare-link updates above: orphaned RC compare links removed, the new `[16.5.0]` link anchored at the previous stable tag (e.g., `v16.4.0...v16.5.0`) — not the latest RC tag — and `[unreleased]` pointing from `v16.5.0` to `main`. When the repo's changelog version-stamping task (`release` mode) does the coalesce, this is handled automatically; still verify the result before pushing.

#### Step 2: Curate the entries — REMOVE these

1. **Prerelease-only fixes** — bugs introduced during the prerelease cycle and fixed in a later RC. If the bug never shipped in a stable release, the fix is noise to stable users.
   - Investigate when a bug was introduced: `git log --oneline v<last_stable>..v<rc_containing_the_fix>` — search this range for the commit that introduced the bug. If the range is large and you know which files are relevant, scope it with `-- path/to/file` to cut noise. If you **find it** in this range, the bug was introduced during the RC cycle and never shipped in stable — apply the merge-or-drop rules below. If you **don't find it**, the bug predates the RC cycle and existed in `<last_stable>` — keep the fix as its own entry.
   - Check the PR description for what was broken and when
   - For RC-only regression fixes where the fix **changed user-visible behavior** of the original feature (e.g., extended an option's accepted values, adjusted a default, broadened a path matcher), **merge** the fix into the original PR's entry: credit both PRs and rewrite the description so it reflects the final shipped state. Don't drop these — stable consumers see the merged behavior, not the intermediate regression.
   - **Pure-restore** fixes (the fix only restores prior behavior without changing the original entry's description) can be dropped.

2. **Refinements to prerelease-only features** — if a new feature was introduced in `rc.0` and then iterated in `rc.1`/`rc.2`, keep only the final description and drop the iteration history

3. **Internal/contributor-only tooling** — yalc publish fixes, git dependency support, CI/build script changes, generator handling of prerelease version formats, local-dev tooling fixes. These don't belong in a user-facing changelog.

#### Step 3: Curate the entries — KEEP these

1. **User-facing fixes for bugs that existed in the previous stable** — if `rc.2` fixes a bug that was in `16.4.0`, that fix matters to stable users upgrading

2. **Compatibility fixes** — language/framework version support, dependency relaxations, etc.

3. **All breaking changes** — API/CLI changes, removed methods, configuration changes, generator output changes. Even if a breaking change was introduced and refined across multiple prereleases, the final breaking change description belongs in stable.

4. **Performance/security improvements affecting all users**

**Scope-tag tagging:** When the repo's changelog defines an inline scope tag (such as `**[Pro]**`; see `AGENTS.md` → **Agent Workflow Configuration**), scope-tagged changes stay in the changelog with that inline tag — do NOT drop them just because they only apply to that scope. Apply the same REMOVE/KEEP rules above based on whether they're prerelease-only iteration vs user-facing changes that ship to users of that scope.

#### Step 4: Investigation process for each entry

For each entry that doesn't obviously fall into a REMOVE or KEEP category above, ask:

- Was this bug present in the last stable release? If no, drop.
- Was this feature introduced in an earlier prerelease and then iterated/refined across later RCs? If yes, keep only the final description and drop the intermediate history.
- Does this matter to someone upgrading from the last stable to this stable? If no, drop.

#### Step 5: Final read-through

Read the resulting stable section as if you're a user upgrading from the previous stable. Every entry should be something you'd want to know about. If an entry only makes sense to someone who tracked the RC cycle, drop it.

**Example reference:** If the repo records a worked prerelease-curation example PR, consult it for a complete example of prerelease changelog curation with detailed investigation notes.

## Examples

Run this command to see real formatting examples from the codebase after resolving the repo's changelog path from `AGENTS.md`:

```bash
CHANGELOG_PATH="${CHANGELOG_PATH:?set CHANGELOG_PATH from AGENTS.md}"
grep -A 3 "^#### " "${CHANGELOG_PATH}" | head -30
```

These examples illustrate the entry **structure** only; use the repo's exact PR-and-author link format from the changelog seam (here shown as `<owner>/<repo>` / `username`).

### Good Entry Example

```markdown
- **Feature Name**: Added a user-visible capability and a one-sentence explanation of what it does and why it helps. [PR 1857](https://github.com/<owner>/<repo>/pull/1857) by [username](https://github.com/username).
```

### Entry with Sub-bullets Example

```markdown
- **Feature Name**: Added new configuration options:
  - `option_one`: What it configures and its default. [PR 1798](https://github.com/<owner>/<repo>/pull/1798) by [username](https://github.com/username)
  - `option_two`: What it configures and its default. [PR 1798](https://github.com/<owner>/<repo>/pull/1798) by [username](https://github.com/username)
```

### Breaking Change Example

```markdown
- **Area Name**: Several methods have been removed from the package. If you're using any of the following, you'll need to migrate:
  - `methodOne()`
  - `methodTwo()`
  - `methodThree()`

**Migration Guide:**

1. Update your imports to the new package/path
2. Replace each removed call with its supported equivalent
```

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
- See the top of the repo's changelog for any additional contributor guidelines
