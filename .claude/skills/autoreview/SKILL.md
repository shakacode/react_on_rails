---
name: autoreview
description: 'Run a structured second-model code review (Codex default, Claude optional) as a closeout gate on a local, branch, or commit diff, then verify every finding against the real code and loop until clean. Use before commit/push/ship in this repo.'
---

# Auto Review

Run a structured second-model review as a **closeout check** before commit, push, or ship,
then loop until the review reports no accepted/actionable findings. This is code review, not
PR merge/approval routing.

This skill is the _discipline layer_. It does not ship its own reviewer — it drives this
repo's existing review tooling and adds the "verify every finding, fix at the right boundary,
re-review until clean" loop on top.

- **Default engine: `/codex review`** (the gstack `/codex` skill → OpenAI Codex CLI, an
  independent model). Codex usually gives the best closeout review and should stay the
  default unless the user asks otherwise.
- **Alternative engine: `/code-review`** (Claude's built-in reviewer; `/code-review ultra`
  for the deep multi-agent cloud pass).
- For PR-comment triage (reacting to review comments already on a GitHub PR), use
  `/address-review` instead — that is a different job.

Use when:

- user asks for "autoreview", "codex review", "Claude review", "second-model review",
  or a final review before commit/ship
- after non-trivial code edits, before the final commit/push/PR
- reviewing a local working tree, a branch, or a single landed commit after fixes

## Contract

This is the portable core. Hold it regardless of which engine runs.

- Treat review output as **advisory**. Never blindly apply it.
- Verify every finding by reading the real code path and adjacent files before acting.
- Read dependency docs/source/types when a finding depends on external (gem/npm/Rails/React) behavior.
- Reject unrealistic edge cases, speculative risks, broad rewrites, and fixes that over-complicate the code.
- Prefer small fixes at the right ownership boundary; no refactor unless it clearly improves the bug class. This matches `AGENTS.md` → "never refactor unrelated code."
- Keep going until the review returns no accepted/actionable findings.
- If a review-triggered fix changes code, rerun the focused tests for the changed surface and rerun the review.
- Security perspective is always included, but it must not cripple legitimate functionality. Report a security finding only when the change creates a concrete, actionable risk or removes an important safety check.
- Be patient. `codex review` runs an external model and can take several minutes on a large diff. Progress that looks quiet is usually still working — do not kill it before ~5 minutes unless it has clearly errored.
- Do not nest reviewers or spawn reviewer panels from inside a review. One bundle, one selected engine, one structured result, then stop.
- Stop as soon as the review comes back clean with no accepted/actionable findings. Do not run an extra review just to get nicer "clean" wording or a redundant second opinion.
- If you reject a finding as intentional/not worth fixing, add a brief inline code comment only when it documents a real invariant or ownership decision a future reviewer should know.
- **Do not push just to review.** Push only when the user asked for push/ship/PR. Follow `AGENTS.md` git boundaries (Pro package edits are ask-first; never force-push `main`/`master`).

## Step 1 — Pick the target

Inspect what changed and choose the diff scope. Base branch in this repo is `origin/main`.

```bash
git status --short
git diff --name-only origin/main...HEAD
git diff --stat origin/main...HEAD
```

- **Dirty local work** (unstaged/staged/untracked in the working tree): review the working
  tree. Use this only when there is an actual local patch — a clean local review just proves
  there is no local patch, not that the branch is good.
- **Branch / PR work** (committed, maybe pushed): review the branch diff against its base.
  If an open PR exists, use its real base instead of assuming `main`:

  ```bash
  base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null || echo main)
  git diff "origin/$base...HEAD" --stat
  ```

- **Single landed commit** (already on `main`, or one commit in a stack): review that commit's
  diff (`git show <sha>`). Reviewing clean `main` against `origin/main` is an empty diff after
  push — point at the commit instead.

Tell the user which target you picked and why.

## Step 2 — Format and lint first

Formatting that moves line locations will stale the review and the engine's line references.
Run autofix and the CI-equivalent lint gate **before** the review (see `AGENTS.md` → Commands /
Boundaries, and `/verify` for the full scope map):

```bash
rake autofix                                   # Prettier + RuboCop autocorrect (never hand-format)
(cd react_on_rails && bundle exec rubocop)     # CI-equivalent OSS Ruby lint
# Also, only when Pro Ruby or RuboCop config changed (Pro edits are ask-first per AGENTS.md):
(cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion)
```

## Step 3 — Run the structured review

Default to Codex. Invoke the engine skill rather than re-deriving its CLI invocation:

- **`/codex review`** — runs `codex review` against the branch diff with a pass/fail gate
  (handles auth probe, timeout, and the diff-scope prompt for you). This is the default.
- **`/code-review`** — Claude's built-in reviewer for the current diff. `/code-review ultra`
  for the deep multi-agent cloud review (user-triggered, billed).

Never silently switch the engine the user asked for. If the requested engine hits model
capacity, retry the same engine a few times rather than swapping it.

## Step 4 — Verify, fix, and loop

For each finding the engine returns:

1. Open the real code path and adjacent files. Confirm the finding is true here, not generic.
2. Accept only concrete, actionable findings (correctness bugs, real regressions, genuine
   security gaps, clear inconsistencies with adjacent code). Reject speculation, nits, and
   broad rewrites — note briefly why.
3. Fix accepted findings with the smallest correct change at the right boundary.
4. Rerun the **targeted** tests for the changed surface, then rerun the review. Use `/verify`'s
   Scope Guide to pick the narrowest covering tests, e.g.:
   - Ruby gem: `bundle exec rspec react_on_rails/spec/react_on_rails/path/to/spec.rb` (+ RBS validate if signatures changed)
   - Dummy/integration: `cd react_on_rails/spec/dummy && bundle exec rspec spec/path/to/spec.rb`
   - TS package: `pnpm --filter react-on-rails exec jest <relative-test-file>`, plus `pnpm run type-check` / `pnpm run lint` for touched TS

Loop Steps 3–4 until the review returns no accepted/actionable findings. Once a rerun comes
back clean, stop — do not spend another long review cycle on redundant confirmation.

### Parallel closeout (optional)

After Step 2 formatting is done, it is fine to run the focused tests and the review
concurrently to save wall-clock. If either forces a code edit, rerun the affected tests and
re-review until clean.

## Final report

Report:

- diff target reviewed (local / branch / commit) and base
- review engine used (`/codex review` or `/code-review`)
- tests/proof run, with pass/fail
- findings accepted vs rejected, briefly why
- the final clean review result, or why a remaining finding was consciously left unfixed

Do not run another review solely to improve the report wording. If the final review came back
with no accepted/actionable findings, report that run as clean.
