# Release-Train Automation — Design

Status: proposed (2026-06-27). Author: release-train automation work.

This is the design/spec for scripting the manual git steps in
[`release-train-runbook.md`](release-train-runbook.md) so the train reads as a
**`release start` → stabilize → `release finish`** arc. It is the implementation
companion to the runbook; the runbook stays the human-facing process doc and
`AGENTS.md` stays the canonical policy.

The verb framing (`start` / `finish`) is borrowed from Gitflow's
`git flow release start|finish` ergonomics. The borrowing is **only the
vocabulary**: the React on Rails train is trunk-based (ephemeral `release/X.Y.Z`,
no long-lived `develop`, cherry-pick forward-port), not Gitflow. See
[Gitflow contrast](#gitflow-contrast).

## Already in place — do NOT rebuild

Two things the runbook implies are manual are already automated. Confirm and lean
on them; do not re-implement.

- **Version is optional on the command line (reads the changelog).**
  [`rakelib/release.rake`](../../rakelib/release.rake) `resolve_version_input`
  (~line 2145) already falls back to `extract_latest_changelog_version`: with no
  version arg, `bundle exec rake release` uses the top `### [X.Y.Z]` changelog
  header when it is newer than `version.rb` (or equal-but-untagged). So once
  `/update-changelog rc` has stamped `### [17.0.0.rc.0]`, a bare
  `bundle exec rake release` cuts rc.0. The runbook's explicit
  `release[17.0.0.rc.0]` form is optional. → **Doc-only fix** (folded into PR 1).
- **Promotion is already release-branch-aware.** `ensure_release_branch_promotes_tagged_rc!`
  and `stable_release_branch_allowed?` already let `rake release[17.0.0]` run _from_
  `release/17.0.0`, validate the tip descends from the accepted RC tag, and reject
  runtime drift after the RC. PR 4's "finish" script orchestrates the steps _around_
  this; the dangerous git/tag logic already lives in Ruby with guards.

## Constraints that shape the design

- **Cut + tag-rc.0 cannot be one atomic command.** The runbook's step-1 note: the
  release CI gate evaluates the _branch tip_, and a freshly-pushed `release/X.Y.Z`
  has no checks yet (`no_checks`). So "create the branch" and "cut rc.0" must be
  two invocations with a CI run between them. `release start` therefore creates +
  pushes + stops; the operator waits for CI, then runs `rake release` to tag rc.0.
- **Forward-porting changelog entries means re-homing them.** On `release/X.Y.Z` a
  fix's entry lives under an RC header (`### [17.0.0.rc.1]`); on `main` it belongs
  under `### [Unreleased]`. A plain `cherry-pick -x` (what `release-forward-port`
  does today) drags RC-header context and tends to conflict or land the entry in
  the wrong section. PR 3 is a changelog _restructure_, not just "stop skipping."

## Decomposition

Four focused PRs in release-train lifecycle order, plus a deferred blog post. Each
PR is independently shippable.

| PR  | Name                                                                | Touches                                                                                          |
| --- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1   | `release start` — auto-create `release/X.Y.Z` on an rc cut          | `rakelib/release.rake`, runbook, helper spec                                                     |
| 2   | `/update-changelog` release-vs-main target                          | `.agents/skills/update-changelog/SKILL.md`, maybe `react_on_rails/rakelib/update_changelog.rake` |
| 3   | `release-forward-port` re-homes changelog entries to `[Unreleased]` | `script/release-forward-port` (+ test)                                                           |
| 4   | `release finish` — promote + close-out scripts                      | new `script/release-finish` (+ test), runbook                                                    |
| 5   | Blog post (deferred until 1–4 ship)                                 | local/untracked draft only                                                                       |

---

## PR 1 — `release start` (full detail)

Make starting a release line a real, guarded verb, and stop letting an rc be cut
off `main` by accident.

### Surface

- **New task `rake "release:start[X.Y.Z]"`** — explicit "begin the X.Y.Z release
  line." Added via `namespace :release do task :start … end` alongside the existing
  top-level `task :release` (Rake allows a task and a same-named namespace).
- **In-`rake release` offer** — when the resolved version is an rc, you're on
  `main`, and `release/X.Y.Z` is missing, `rake release` offers to run the same
  start logic inline (`Start the X.Y.Z release line now? [y/N]`).

Both paths share one helper, so behavior is identical.

### `rake "release:start"` behavior

1. Determine `current_branch`; **require `main`** (abort otherwise — the line is
   cut from `origin/main`). Reuse `ReactOnRails::GitUtils.uncommitted_changes?`.
2. Resolve the **base** version `X.Y.Z`:
   - arg present → validate strict stable form `\A\d+\.\d+\.\d+\z` (reject rc /
     prerelease forms — the branch name is the base);
   - no arg → derive from the changelog: if the top header is `X.Y.Z.rc.N`, base =
     `release_base_version` → `X.Y.Z` (printing which release line was derived from
     the changelog); otherwise abort asking for an explicit `X.Y.Z`.
3. `release_branch = "release/#{base}"`.
4. `git fetch origin`.
5. **Existence guard** — if `release_branch` exists locally or on `origin`, abort:
   `release/X.Y.Z already exists; git checkout release/X.Y.Z && bundle exec rake release`.
6. Create + publish + switch: `git checkout -b release/X.Y.Z origin/main` then
   `git push -u origin release/X.Y.Z`.
7. Print next steps: wait for ≥1 CI run on the branch tip; ensure the rc changelog
   header is present (`/update-changelog rc` on the branch — PR 2); then
   `bundle exec rake release` to cut rc.0 (version read from `CHANGELOG.md`).
8. Optional 2nd arg `dry_run` mirroring `release`: print the plan, create nothing.

### In-`rake release` offer behavior

Inserted at [`release.rake:2687`](../../rakelib/release.rake), right after
`is_prerelease = …` and before `ensure_release_branch_matches_target_base!`. In
normal mode `release_root == monorepo_root`, so it operates on the real repo; the
`git pull --rebase` at ~line 2675 has already refreshed `main`.

Fires **only when `current_branch == "main"` and the resolved version is an rc**
(`rc_prerelease_version?`). Then:

- **Branch missing** → `y/N` prompt; on `y`, run the shared start helper (fetch →
  guard → create → push → next-steps) and `exit 0` before any tagging; on `n`,
  abort without creating anything.
- **Branch already exists** (local or `origin`) → **stop**: "release/X.Y.Z exists;
  `git checkout release/X.Y.Z` and re-run." This is the new guard against tagging an
  rc off a drifted `main`.
- **Not a TTY** → abort with the manual `git checkout -b … && git push` recipe
  (never auto-create unattended).
- **Dry-run** → print `DRY RUN: would offer to create release/X.Y.Z …` and return.
- Not rc, or not on `main` → no-op. Feature-branch rc cuts (the existing
  prerelease escape hatch) and rc.1+ cut from the branch are untouched.

### New top-level helpers (alongside the other `def`s, ~line 480)

- `rc_prerelease_version?(gem_version)` → `parse_gem_version_components(...)[:prerelease_type] == "rc"`.
- `local_or_remote_branch_exists?(monorepo_root:, branch:)` — checks
  `git rev-parse --verify --quiet refs/heads/<b>`, then
  `git ls-remote --exit-code --heads origin`.
- `start_release_line!(monorepo_root:, release_branch:, dry_run:)` — fetch +
  existence-guard + `checkout -b … origin/main` + `push -u` + next-steps. Shared by
  the task and the offer.
- `maybe_offer_release_branch_cut!(...)` — the main-only / rc-only decision matrix;
  the single call added to the task body.
- Message builders mirroring the existing `handle_release_branch_identity_violation!`
  dry-run/abort split.

### Doc fix (folds in the "1b" finding)

Update runbook **step 1** to show the bare `bundle exec rake release` (version read
from the changelog), introduce `rake "release:start[17.0.0]"` and the in-`rake
release` offer, and drop the implication that you must pass `17.0.0.rc.0`.

### Tests

`react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb` (match its
existing style):

- `rc_prerelease_version?` — rc vs beta/stable/nil.
- `local_or_remote_branch_exists?` — against a `mktemp` git repo (local branch,
  remote-only branch, absent).
- `maybe_offer_release_branch_cut!` decision matrix: rc-on-main-missing → offer;
  rc-on-main-exists → guard abort; non-rc → no-op; non-main → no-op; non-TTY →
  abort.
- `release:start` base resolution: explicit `X.Y.Z` accepted; rc/prerelease arg
  rejected; changelog-derived base; existence guard.

---

## PR 2 — `/update-changelog` release-vs-main target (approach)

**Problem.** The skill's finalize step hard-stops unless you're on `main`. During
rc stabilization, a fix's changelog entry must land on `release/X.Y.Z`, not `main`.

**Approach.** Add a **target** dimension to the skill:

- `main` (default, today's behavior) — entries to `[Unreleased]`, branch off
  `main`, PR targets `main`.
- `release` — resolve the active `release/X.Y.Z` (explicit arg, or detect the lone
  `release/*` / the `agent-coord` phase), branch off it, PR targets it, entries go
  under the in-progress rc section (the rc stamping moves `[Unreleased]` entries
  under the new header).

`/update-changelog` **asks "release or main?"** when an active release line is
detected (per the request). The `update_changelog.rake` task is largely
branch-agnostic (edits `CHANGELOG.md` in place); the skill drives branch/PR
targeting.

**Open detail for PR-2 design:** compare-link base. Links hardcode `…main`
([`update_changelog.rake`](../../react_on_rails/rakelib/update_changelog.rake)
`update_changelog_links`). On a release branch the `[unreleased]` link semantics
differ; decide whether release-target entries keep `…main` anchoring or the task
gains a base-branch parameter. This interacts with PR 3 (how rc entries reconcile
into `main`'s `[Unreleased]`).

---

## PR 3 — `release-forward-port` re-homes changelog entries (approach)

**Problem.** Today the helper cherry-picks `-x` fix commits (carrying their
changelog hunks under an RC header) and marks version-bump commits `MANUAL`. Result
on `main`: entries conflict or land under an RC header instead of `[Unreleased]`.

**Approach (recommended).** Keep code forward-port (cherry-pick `-x`) as-is; add a
dedicated **changelog reconciliation** pass that guarantees every release-branch
entry exists under `main`'s `[Unreleased]`, de-duplicated by PR number against
existing `main` entries, and drops any RC-header section that a pick introduced on
`main`. Reuse the changelog parsing already in `update_changelog.rake`
(`parse_changelog_sections`, `consolidate_changelog_blocks`,
`deduplicate_block_entries`).

Surface options to pin at PR-3 design: a `--changelog` mode vs always-reconcile;
where the reconcile runs relative to the cherry-pick loop. The release branch may
hold entries under several rc sections (`rc.0`, `rc.1`) plus `[Unreleased]`; all
collapse into `main`'s `[Unreleased]`.

**Tests.** Add a `script/release-forward-port` changelog re-homing test (the repo
uses `*-test.bash` harnesses, e.g. `ci-changes-detector-test.bash`).

---

## PR 4 — `release finish` (approach)

`script/release-finish` orchestrates the runbook's steps 4–5, wrapping the existing
rake promotion guards with confirmations:

- **Promote (step 4):** `git checkout release/X.Y.Z`; verify the tip equals the
  accepted RC (`git diff --stat` against `vX.Y.Z.rc.N` is empty); collapse rc →
  stable changelog (`/update-changelog release`); `bundle exec rake release[X.Y.Z]`
  (all promotion guards already enforced in `release.rake`).
- **Close out (step 5):** forward-port remaining commits to `main` (uses PR 3),
  then `git push origin --delete release/X.Y.Z` (tags are the durable record).

Surface to pin at PR-4 design: one script with `promote` / `close-out`
subcommands vs a single linear flow with a confirmation between phases. This PR is
mostly orchestration + safety prompts; lowest novel logic.

---

## Workstream 5 — blog post (deferred)

Write **after** PR 1–4 ship, documenting the real automation. Keep it a
local/untracked draft (repo convention: unpublished posts stay local). Angle:
"Shipping a careful library release without freezing main: a trunk-based release
train, automated with agents." Use Gitflow as the teaching foil (link the Atlassian
tutorial), not the adopted model.

## Gitflow contrast

For rationale and the future blog. Atlassian's own Gitflow page now calls it "a
legacy Git workflow … fallen in popularity in favor of trunk-based workflows … can
be challenging to use with CI/CD."

| Dimension            | Gitflow                           | RoR release train                                        |
| -------------------- | --------------------------------- | -------------------------------------------------------- |
| Long-lived `develop` | Yes; features accumulate there    | No — `main` is the trunk and never freezes               |
| Release branch       | Off `develop`, feature-freeze     | Off `main`, **ephemeral** `release/X.Y.Z`, deleted after |
| Finish a release     | **Merge** into `main` + `develop` | **Promote in place** (drop `-rc`); tags are the record   |
| Fix back-propagation | Merge release → `develop`         | **`cherry-pick -x` forward-port** to `main`              |
| Hotfix               | `hotfix/*` off `main` → both      | "pick one direction per fix, record it"                  |

What we take: the `release start` / `release finish` vocabulary, and the
release-branch = feature-freeze / merge-fixes-back concepts as framing. What we
reject: long-lived `develop` (our `main` is the trunk) and merge-based finish
(ephemeral branch + `-x` + tags is better for a version-pinned library).

## Sequencing

Build in order 1 → 2 → 3 → 4 (lifecycle order). PR 4's close-out depends on PR 3.
PRs 2 and 3 are the two halves of the cross-branch changelog flow and share the
`update_changelog.rake` parsing; design them with that interaction in mind. Each PR
keeps the existing release-gate, version-policy, and CI parity tests green and adds
its own.
