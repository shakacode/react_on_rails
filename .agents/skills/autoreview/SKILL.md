---
name: autoreview
description: 'Run a structured second-model code review as a closeout gate on a local, branch, or commit diff, then verify every finding against the real code and loop until clean. Use before commit/push/ship in this repo.'
---

# Auto Review

Run a structured second-model review as a **closeout check** before commit, push, or ship,
then loop until the review reports no accepted/actionable findings. This is code review, not
PR merge/approval routing.

This skill is the discipline layer. It does not ship its own reviewer; it drives available
review tooling and adds the "verify every finding, fix at the right boundary, re-review until
clean" loop on top.

- **Default engine: `codex review`**. It is a concrete CLI command and supports
  local/branch/commit review modes.
- **Alternative engine: Claude review tooling** when the current Claude Code environment provides
  it, such as `/code-review` or `/code-review ultra`. Treat these as environment-specific, not
  repo-local commands.
- For PR-comment triage (reacting to review comments already on a GitHub PR), use
  `.agents/skills/address-review/SKILL.md`; Claude Code exposes it as `/address-review`.

Use when:

- user asks for "autoreview", "codex review", "Claude review", "second-model review",
  or a final review before commit/ship
- after non-trivial code edits, before the final commit/push/PR
- reviewing a local working tree, a branch, or a single landed commit after fixes

## Contract

This is the portable core. Hold it regardless of which engine runs.

- Treat review output as **advisory**. Never blindly apply it.
- Verify every finding by reading the real code path and adjacent files before acting.
- Read dependency docs/source/types when a finding depends on external library/framework behavior.
- Reject unrealistic edge cases, speculative risks, broad rewrites, and fixes that over-complicate the code.
- Prefer small fixes at the right ownership boundary; no refactor unless it clearly improves the bug class. This matches `AGENTS.md`: never refactor unrelated code.
- Keep going until the review returns no accepted/actionable findings; once it comes back clean, stop. Do not run an extra review just to get nicer "clean" wording or a redundant second opinion.
- If a review-triggered fix changes code, rerun the focused tests for the changed surface and rerun the review.
- Security perspective is always included, but it must not cripple legitimate functionality. Report a security finding only when the change creates a concrete, actionable risk or removes an important safety check.
- Be patient. `codex review` runs an external model and can take several minutes on a large diff. Progress that looks quiet is usually still working; do not kill it before about 5 minutes unless it has clearly errored.
- Do not launch multiple reviewers by default. One selected engine, one structured result, then verify it.
- A gated second-engine pass is appropriate only when the user asks or the diff falls into the
  `AGENTS.md` high-risk / hosted-CI-ready / force-full hosted-CI / benchmark categories (labels
  per `AGENTS.md` → **Agent Workflow Configuration**). Run it after the primary review is
  clean, keep it to one extra pass, and verify its findings the same way.
- If you reject a finding as intentional/not worth fixing, add a brief inline code comment only when it documents a real invariant or ownership decision a future reviewer should know.
- **Do not push just to review.** Push only when the user asked for push/ship/PR. Follow `AGENTS.md` git boundaries (never force-push `main`/`master`).

## Step 1 - Pick the target

Inspect what changed and choose the diff scope. Base branch in this repo is `origin/main`.

```bash
git status --short --untracked-files=all
git diff --name-only origin/main...HEAD
git diff --stat origin/main...HEAD
git diff --stat
git diff --cached --stat
git ls-files --others --exclude-standard
```

- **Dirty local work** (unstaged/staged/untracked in the working tree): review the working
  tree with `codex review --uncommitted`. Use this only when there is an actual local patch; a clean local review just proves
  there is no local patch, not that the branch is good.
- **Branch / PR work** (committed, maybe pushed): review the branch diff against its base with
  `codex review --base origin/main` or the PR's real base.
  If an open PR exists, use its real base instead of assuming `main`:

  ```bash
  base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null || echo main)
  git diff "origin/$base...HEAD" --stat
  ```

- **Branch plus dirty local work**: either commit the intended local changes before the final
  branch review, or run two reviews: one branch review for committed changes and one
  `--uncommitted` review for staged/unstaged/untracked local changes. Staging alone does not put
  changes into the branch diff. Do not let untracked files fall out of scope.
- **Single landed commit** (already on `main`, or one commit in a stack): review that commit's
  diff (`git show <sha>`). Reviewing clean `main` against `origin/main` is an empty diff after
  push; point at the commit instead.

Tell the user which target you picked and why.

## Step 2 - Format and lint first

Formatting that moves line locations will stale the review and the engine's line references.
Use `AGENTS.md` and `/verify` for the actual check set. Before a closeout review:

- Run `git diff --check origin/main...HEAD` for committed branch content, plus `git diff --check`
  and `git diff --cached --check` when there is local dirty work.
- Run the repo's format/autofix command (see `AGENTS.md` → **Agent Workflow Configuration**) when
  formatting or autocorrectable lint failures are present or likely; let those autofix tools make
  formatting/autocorrect changes instead of hand-formatting.
- Run the narrow lint/test checks that cover the changed surface. Before committing, include the
  CI-equivalent lint gate(s) required by `AGENTS.md`, including any package-specific lint that
  applies only when that package's files or its linter config changed.

## Step 3 - Run the structured review

Default to Codex. Verify it is available first (`command -v codex`); if not, fall back to the Claude
review tooling described in the intro. If neither engine exists in the current environment, stop and
tell the user which review engines are missing instead of improvising a different review scope. Pick
the command that matches Step 1:

```bash
# Dirty local patch, including staged, unstaged, and untracked files.
codex review --uncommitted

# Branch or PR diff.
base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null || echo main)
codex review --base "origin/$base"

# Single commit.
codex review --commit <sha>
```

Prefer explicit target selection over custom focus text. Some Codex CLI versions reject a custom
prompt when `--base`, `--uncommitted`, or `--commit` is present. If that happens, keep the explicit
target command and continue without the prompt rather than accidentally reviewing the wrong diff.

When the installed CLI accepts focus text with the selected target flag, keep the same target from
Step 1 and append the prompt there:

```bash
codex review --base "origin/$base" "Focus on performance- or framework-sensitive regressions (per AGENTS.md), generated output, and repo workflow correctness."
```

For longer instructions, create an ignored scratch file, for example
`.context/autoreview-focus.md` if your workspace provides `.context/`, or substitute another ignored
path. Read from stdin only when the selected review engine supports that mode without dropping the
target:

```bash
codex review --base "origin/$base" - < .context/autoreview-focus.md   # create this ignored scratch file first
```

Never silently switch the engine the user asked for. If the requested engine hits model
capacity, retry the same engine a few times rather than swapping it.

### High-risk second pass

For high-risk changes in the `AGENTS.md` hosted-CI-ready, force-full hosted-CI, or benchmark
categories (labels per `AGENTS.md` → **Agent Workflow Configuration**), or when the user asks
for a panel/second model, run one additional review after the primary review is clean:

- If the primary review used `codex review`, use Claude review tooling if it is available in the
  current environment, such as `/code-review` or `/code-review ultra`.
- If the primary review used Claude review tooling, use `codex review` with the same target and
  any focus instructions the installed CLI supports.
- If no second engine is available, say so and continue with the clean primary review plus local
  verification.

Do not run a panel for small focused PRs unless the user asks. This matches `AGENTS.md`: use at
most one inline-commenting AI reviewer for small PRs.

## Step 4 - Verify, fix, and loop

For each finding the engine returns:

1. Open the real code path and adjacent files. Confirm the finding is true here, not generic.
2. Accept only concrete, actionable findings (correctness bugs, real regressions, genuine
   security gaps, clear inconsistencies with adjacent code). Reject speculation, nits, and
   broad rewrites; note briefly why.
3. Fix accepted findings with the smallest correct change at the right boundary.
4. Rerun the **targeted** tests for the changed surface, then rerun the review. Use `/verify`'s
   Scope Guide and the repo's commands/tests (see `AGENTS.md`) to pick the narrowest covering
   tests for the changed surface, e.g. the unit spec for a library-code change, the
   integration/app spec for an integration change, and the package test plus type-check/lint for
   touched TypeScript. Also rerun any signature/type validation when typed interfaces changed.

Loop Steps 3-4 until the review returns no accepted/actionable findings. Once a rerun comes
back clean, stop; do not spend another long review cycle on redundant confirmation.
If the same finding recurs after two fix attempts, or the review starts cycling through speculative
issues, stop, report the loop, and ask the user whether to continue.

### Parallel closeout (optional)

After Step 2 formatting is done, it is fine to run the focused tests and the review
concurrently to save wall-clock. If either forces a code edit, rerun the affected tests and
re-review until clean.

## Final report

Report:

- diff target reviewed (local / branch / commit) and base
- review engine used (`codex review` or the available Claude review command)
- tests/proof run, with pass/fail
- findings accepted vs rejected, briefly why
- PR label recommendation from `AGENTS.md` (none, the hosted-CI-ready label, the force-full
  hosted-CI label, a benchmark label, or a valid combination of these — exact label names per
  `AGENTS.md` → **Agent Workflow Configuration**) when the work is headed to a PR
- the final clean review result, or why a remaining finding was consciously left unfixed

Do not run another review solely to improve the report wording. If the final review came back
with no accepted/actionable findings, report that run as clean.
