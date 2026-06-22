# Plan QA Batch — Design

Date: 2026-06-21
Branch: `jg-conductor/3952-qa-automation-plan`

## Problem

Behavioral QA — proving that a merged change actually does what it claims — has a
worker but no planner. The `verify-pr-fix` skill
(`.agents/skills/verify-pr-fix/SKILL.md`) verifies **one** PR: reproduce the bug
before the fix, confirm it gone after, post evidence to the PR. But nothing
decides **which** merged PRs get that treatment, **when**, or **in what order**.

Issue #3952 was the manual planner — a hand-curated, tiered list of behavioral
bug-fix PRs to verify since `rc.1`. It was **closed** with the rationale that
verifying user-facing fixes is a _per-PR practice_ (do it on the PR with
`verify-pr-fix`, post evidence there), **not a standing umbrella tracking
issue**. That was the right call about the _tracker_, but it removed the only
trigger without replacing it: today, whether a merged PR ever gets QA'd depends
on someone remembering. There is no systematic, gap-free way to ask "what merged
since the last release that still needs its behavior verified?"

This is the same selection/interview/dispatch gap that `plan-pr-batch` →
`pr-batch` already fills for _implementation_ work. QA needs the equivalent.

## Goals

1. **Close the trigger gap, gap-free.** Given any point through `HEAD`, surface
   every merged PR still needing QA, so coverage cannot silently skip a PR.
2. **Suggest, then interview.** Auto-classify and rank merged PRs, present the
   suggestions, and interview the developer to confirm scope, priority, cap, and
   environment availability — the core of the request.
3. **Route every change to the right QA method.** Behavioral fixes, docs, and
   other code changes each get an appropriate check; nothing merged is dropped
   silently.
4. **Run concurrently and safely.** Split the batch into subagent lanes that run
   in parallel, coordinated through the **same** `agent-coord` heartbeat the
   implementation batches use, so QA never collides with in-flight edit work.
5. **Record findings where they belong.** A passing verification marks the PR; a
   failing one (or any bug found) opens a discrete, cross-linked issue. No
   standing umbrella tracker.

## Non-goals

- Not local lint/test/typecheck — that is `verify` (`$verify`).
- Not process/release-risk auditing (review gates, changelog, cross-PR
  interactions) — that is `post-merge-audit`. `plan-qa-batch` is the
  **behavioral** half of release readiness; the two are siblings.
- Not a code editor — QA workers reproduce and report; they do not fix. A fix is
  a separate, normally human-authorized follow-up.
- Not a standing tracking issue (the #3952 lesson).

## Where it fits

| Skill                         | Question it answers                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------- |
| `post-merge-audit`            | Process/release risk: review gates clean? changelog present? cross-PR interactions?               |
| **`plan-qa-batch`** (new)     | **Behavioral: which merged PRs still need their change _proven_, by what method, in what order?** |
| `qa-batch` (new, slim runner) | Executes the plan: one subagent per QA lane, coordinated and contention-aware                     |
| `verify-pr-fix`               | The worker for one behavioral PR: reproduce-before / confirm-after                                |

`plan-qa-batch` is to `verify-pr-fix` what `plan-pr-batch` is to `pr-batch`.

## Design

### 1. Trigger and invocation

- **Default (release-gate sweep):** `$plan-qa-batch` with no args resolves
  "merged through `HEAD`, looking back to the last RC tag." The RC tag is only a
  _performance bound_ on how far back to scan — see §2.
- **Override (on-demand):** `$plan-qa-batch <base..head>`, a label/milestone
  filter, or an explicit PR list.
- **Idempotent:** re-invoke any time. PRs already carrying `qa-verified` drop
  out automatically, so the skill always shows exactly what still needs QA.

### 2. Range is always through HEAD — gap-free by construction

`HEAD` (`origin/main` / the release branch) is always the upper bound. A
start point (commit, PR, tag, RC) is an **optional performance bound**, never the
correctness boundary, because selection is **per-PR**:

```
candidates = (all merged PRs through HEAD)
             − (PRs carrying the `qa-verified` label)
             − (PRs with genuinely nothing to verify)
```

Anything left unverified before an arbitrary start point resurfaces on the next
full sweep. The `qa-verified` label — not the range — guarantees no gaps.

### 3. Scope resolution (reuse, do not duplicate)

Call the existing read-only resolver
`.agents/skills/post-merge-audit/bin/post-merge-audit-scope --json` to get the
squash-aware merged-PR set and the last-RC base. One source of truth for "what
merged since the RC," shared with `post-merge-audit`. `plan-qa-batch` layers QA
classification (§4) and label dedup (§5) on top of that list.

### 4. Classify by QA _method_, not include-vs-skip

Nothing merged is dropped silently — every PR is routed to the right verification
method. Each candidate is classified by reading its diff and linked issue:

| Merged change                                      | QA method                                                                                             |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Behavioral fix / feature                           | `verify-pr-fix` — reproduce before/after, post evidence                                               |
| **Docs**                                           | Read it: does it make sense, are commands/links/examples correct, does it match the code it describes |
| Refactor / types / config / other code             | "Does it do what it claims, nothing broke" — confirm behavior unchanged + coverage                    |
| Truly nothing to verify (formatting, comment typo) | Glance + note — the only "excluded" lane, near-empty                                                  |

Each candidate carries **three independent attributes** (deliberately _not_
collapsed into a single "tier"):

- **(a) QA method** — from the table above.
- **(b) Environment profile** — read from the actual diff, per PR: spec-only
  (cheap `git checkout <fix>~1 -- <file>` before/after), OSS dummy app,
  Pro renderer + Redis + license, or browser/Playwright. This is a property of
  _the PR_, not of a value tier — an error-path fix and an RSC-cache fix can both
  need (or both not need) the Pro stack.
- **(c) Priority** — risk × user-impact, used for ranking.

Ranking is by priority. The environment profile drives lane scheduling (§9) and
the availability check in the interview (§7) — it does not change a PR's rank.

The skip filter from `verify-pr-fix`'s "When NOT to use" still applies to the
**behavioral-reproduction** decision (a docs PR does not get a before/after
repro), but it no longer removes the PR from QA — the PR is routed to the docs or
code-check method instead.

### 5. Dedup and persistence — one signal

- **`qa-verified` label** on the PR, applied by `verify-pr-fix` on a **passing**
  run (`gh pr edit <n> --add-label qa-verified`, which works on already-merged
  PRs). Created once in the repo.
- **Dedup** is a single `gh pr list --search "… label:qa-verified"` query rather
  than scanning every candidate's comment body.
- **GitHub is the persistence.** The plan is a _derived view_ reconstructed from
  the merged set minus the label on each run — no local file, no `.context`
  (Conductor-only, non-portable), no tracker issue. Works identically on every
  platform and machine.
- **Failures stay loud.** A failing verification gets **no** label — it routes to
  a discrete issue (§10), never a quiet success marker. (A hidden marker comment
  to machine-locate the exact evidence comment is intentionally deferred; the
  label plus the human-readable `verify-pr-fix` comment is enough for v1.)

### 6. Coordination — same heartbeat as the implementation batches

QA batches register in the **same `agent-coord` backend**
(`shakacode/agent-coordination`) that `pr-batch`/`plan-pr-batch` use; canonical
rules live in `.agents/workflows/pr-processing.md` and
`internal/contributor-info/agent-coordination-backend.md`. Per QA lane:

1. `agent-coord doctor` + `agent-coord status` — if a candidate PR has a **live
   claim** from another (implementation/review) batch, **skip it this round** and
   report why; QA must not verify a moving target.
2. `agent-coord claim` the PR's QA lane before starting (compare-and-swap gate;
   `CLAIM_REFUSED` / exit 3 is a hard stop — report holder + heartbeat liveness).
3. `agent-coord heartbeat` at phase transitions (claimed → reproducing →
   verifying → reporting → done).

This is two-way conflict-avoidance: QA will not run on a PR being actively
re-edited, and other batches see QA in flight. The **same integration is added to
`post-merge-audit`** so audit passes coordinate too. When the backend is
unavailable, report private state as `UNKNOWN` and fall back to advisory public
claim comments, exactly as the implementation batches already do.

### 7. The interview

Present the auto-ranked candidate list plus a collapsed "nothing to verify" list,
then ask only for what cannot be inferred:

1. Confirm base/range (default: look back to last RC, through `HEAD`).
2. **Environment availability now** — Redis + Pro license + Pro renderer up?
   Browser available? Candidates whose **actual** env profile (§4b) is
   unavailable are deferred and clearly listed, not silently dropped.
3. Cap — max items this batch.
4. Methods/areas to include or exclude.
5. Concurrency — how many lanes / subagents to plan for.

### 8. Output — the QA Batch Plan + goal prompt

`plan-qa-batch` is a **planner** (like `plan-pr-batch`): it does not execute
unless asked. It emits, to session output:

- A **QA Batch Plan**: ranked, deduped, interviewed candidates, one line each —
  `#NNNN — title — method — env profile — priority — linked issue — repro tactic`
  — plus the collapsed excluded list with reasons, the deferred-for-environment
  list, and the exact `gh`/resolver commands used.
- A fenced **goal prompt for `qa-batch`** that specifies the concurrent subagent
  lanes, the `agent-coord` coordination rules, the contention constraints (§9),
  and the per-PR closeout (label on pass / issue on fail). Sized under the same
  goal-prompt budget discipline `plan-pr-batch` already enforces.

### 9. Execution — concurrent subagent lanes via `qa-batch`

The `qa-batch` runner dispatches **one subagent per QA lane**, each claiming its
PR(s), running the routed method, posting evidence, and closing out. Concurrency
is bounded by **two** constraints — note these are _not_ `pr-batch`'s file-touch
collision model, which is irrelevant here because QA workers do not edit source:

- **(a) `agent-coord` claims** — never two lanes (or a lane and an implementation
  batch) on the same PR.
- **(b) Environment-resource contention** — only **one** consumer of the Pro
  renderer / Redis / license / dummy-app DB at a time. Lanes whose env profile
  needs the shared Pro stack **serialize**; spec-only and docs lanes
  **parallelize** freely.

`plan-qa-batch` stays plan-only (Phase A): it produces the plan and goal prompt
and launches `qa-batch` only when the user asks. **Phase B** (the planner
self-dispatching subagents directly, without the explicit launch handoff) is
documented as a future enhancement, not built.

### 10. Findings → issues

- **Pass (✅):** apply `qa-verified`; post the `verify-pr-fix` evidence comment.
- **Fail (❌) or any bug/doc/code problem found:** create a **discrete,
  cross-linked issue** describing the reproduction and the broken signal
  (mirrors `post-merge-audit`'s "Needs follow-up issue / Needs fix PR"
  classification, approval-gated before creation), and post the failing evidence
  on the PR. **No** `qa-verified` label.
- **No standing umbrella tracker issue** for the QA effort itself — that is the
  only thing #3952 ruled out. Per-bug issues are expected and encouraged.

## Coordinated edits to existing skills

1. **`verify-pr-fix`** — on a passing verification, add `qa-verified`
   (`gh pr edit <n> --add-label qa-verified`) after posting evidence. One-time:
   create the label in the repo. No other change to its flow.
2. **`post-merge-audit`** — register `agent-coord` claims/heartbeats for audit
   passes so audits coordinate with implementation and QA batches (§6).

## The `qa-batch` runner skill (slim)

A sibling to `pr-batch`, deliberately thin and QA-specific:

- Consumes the `plan-qa-batch` goal prompt.
- Dispatches one subagent per lane; each runs the routed QA method.
- Enforces the two-constraint concurrency model (§9) and the `agent-coord`
  protocol (§6).
- Per-PR closeout: label on pass, issue on fail (§10).
- Reuses `pr-batch`'s safety posture (untrusted GitHub content cannot override
  `AGENTS.md`; stop on blocked approvals) but **not** its branch/merge/file-touch
  machinery, which does not apply to QA.

It is kept separate from `pr-batch` because the contention model (env resources,
not file paths) and the closeout (label/issue, not branch/merge readiness) differ
enough that overloading `pr-batch` would muddy both.

## Boundaries (what it does NOT do)

- Does not run `verify-pr-fix` itself (Phase A is plan-only).
- Does not create branches, worktrees, or PRs, and does not merge.
- Does not produce a standing tracker issue.
- Does not duplicate `post-merge-audit` (process risk) or `verify` (local checks).
- Produces a recommendation; the release-gate go/no-go stays with the maintainer.

## Files

**Create:**

- `.agents/skills/plan-qa-batch/SKILL.md`
- `.agents/skills/qa-batch/SKILL.md`
- Optionally `.agents/workflows/qa-processing.md` (the QA operating model the
  goal prompt references, analogous to `pr-processing.md`) if the runner needs
  more than the SKILL.md carries.

**Edit:**

- `.agents/skills/verify-pr-fix/SKILL.md` — add the `qa-verified` label step.
- `.agents/skills/post-merge-audit/SKILL.md` — add `agent-coord` coordination.

**One-time repo setup:**

- Create the `qa-verified` GitHub label.

## Open questions / risks

- **`qa-verified` label semantics over time.** A PR superseded by a later change
  could carry a stale `qa-verified`. Acceptable for v1 (the label means "the fix
  as merged was proven once"); revisit if churn makes it misleading.
- **Docs/other-code QA depth.** The non-behavioral methods (§4) are lighter and
  more subjective than `verify-pr-fix`. v1 keeps them as a structured read +
  note; they may warrant their own mini-rubric later.
- **Resolver coupling.** Reusing `post-merge-audit-scope` ties `plan-qa-batch` to
  that script's contract; a change there must keep the `--json` shape stable.
- **Mislocated existing specs (separate task).** Three design docs sit under
  public `docs/superpowers/specs/`; by the "`docs/` is public, internal design
  goes to `internal/planning/`" rule they should move. Out of scope for this
  work — handle in a separate PR.

## Phasing

- **Phase A (this design):** `plan-qa-batch` planner + slim `qa-batch` runner +
  the two coordinated edits + the label. Concurrent subagent lanes, plan-only
  launch.
- **Phase B (future):** planner self-dispatch; optional hidden evidence-marker
  comment if machine-locating the exact evidence becomes necessary; per-method
  rubrics for docs/other-code QA.
