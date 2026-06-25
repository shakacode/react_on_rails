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

- **Default (release-gate sweep):** `$plan-qa-batch` with no args runs the
  authoritative unbounded backlog query (§3) and uses the last-RC window only to
  order/prioritize what it surfaces — never to filter (§2).
- **Override (on-demand):** `$plan-qa-batch <base..head>`, `--full` (drop the
  since-RC ordering window and present the entire backlog flat, §3), a
  label/milestone filter, or an explicit PR list.
- **Idempotent:** re-invoke any time. PRs already carrying a terminal QA label
  (`qa-verified` or `qa-skipped`, §5) drop out automatically, so the skill always
  shows exactly what still needs QA.

### 2. Backlog is defined by labels, not the range — gap-free by construction

`HEAD` (`origin/main` / the release branch) is always the upper bound. The QA
backlog is defined **only** by terminal labels, so the range can never silently
drop a PR:

```
backlog = (all merged PRs through HEAD)
          − (PRs labeled `qa-verified`)   ← passed QA (§5)
          − (PRs labeled `qa-skipped`)    ← reviewed, nothing to verify (§5)
```

Every merged PR ends in exactly one terminal state — `qa-verified` or
`qa-skipped` — so the unverified set is precisely the PRs with neither label.
**The authoritative, unbounded label query (§3) runs on every invocation**, so a
PR merged before the last RC that was never QA'd is never dropped — the RC window
is only an ordering/prioritization hint, never a filter that removes unlabeled
PRs. The labels — not the range — guarantee no gaps, and because a `qa-skipped`
PR is never re-presented, the **backlog** (future work) stays bounded to
unlabeled PRs only. (The `qa-skipped` _set_ itself grows monotonically with the
repo's formatting/typo history; that is harmless because it never re-enters the
backlog, but it is not "bounded.")

### 3. Scope resolution — label query is authoritative, resolver is an optimization

The authoritative backlog is always the **unbounded, paginated** label query, run
on every invocation (not just `--full`):

```sh
gh pr list --state merged --search "-label:qa-verified -label:qa-skipped" \
  --limit 9999   # iterate pages if the repo can exceed the search cap (~1000)
```

`gh pr list` defaults to `--state open` and `--limit 30` and the search backend
caps at ~1000 results, so the skill MUST set `--state merged`, a high `--limit`,
and page explicitly — otherwise the "gap-free" promise silently truncates.

The read-only resolver
`.agents/skills/post-merge-audit/bin/post-merge-audit-scope --json` is then used
**only as an optimization** to order/prioritize the common since-RC window, never
to filter the backlog. Two real constraints when calling it (verified against the
script): it **hard-fails (`return 1`)** when no `*.rc.*` tag is in head history
and `--base` is omitted, so `plan-qa-batch` always passes `--base origin/main`
explicitly and treats any non-zero exit as "optimization unavailable" — the label
query above remains the unconditional source of truth. `plan-qa-batch` then
layers QA classification (§4) on the resulting set.

### 4. Classify by QA _method_, not include-vs-skip

Nothing merged is dropped silently — every PR is routed to the right verification
method. Each candidate is classified by reading its diff and linked issue:

| Merged change                                      | QA method                                                                                                 |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Behavioral fix / feature                           | `verify-pr-fix` — reproduce before/after, post evidence                                                   |
| **Docs**                                           | Read it: does it make sense, are commands/links/examples correct, does it match the code it describes     |
| Refactor / types / config / other code             | "Does it do what it claims, nothing broke" — confirm behavior unchanged + coverage                        |
| Truly nothing to verify (formatting, comment typo) | Glance + note, then apply `qa-skipped` (§5) so it never resurfaces — the only "excluded" lane, near-empty |

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

#### Classification mechanism

Classification is the correctness boundary (a wrong "nothing to verify" silences a
PR), so it is explicit, not ad hoc:

1. **Heuristic first pass** on the file-touch set (reuse `plan-pr-batch`'s
   `pr-file-touch-map`): docs-only, comment/format-only, and code path sets route
   to a provisional method.
2. **LLM adjudication** for anything ambiguous, reading the diff + linked issue
   against the §4 table. The prompt and its tie-breaks live in the SKILL.md so
   every run applies the same rule, not an implementer's invention. This step
   emits **three** artifacts per PR — QA method, env profile, and a **provisional
   `repro tactic`** (e.g. `git checkout <fix>~1 -- <file>` + spec, or "boot Pro
   dummy, hit route X"). The tactic is provisional: `verify-pr-fix` finalizes it
   at execution time, so the plan is actionable before launch without over-fitting.
3. **No silent "nothing to verify".** A PR routed to the `qa-skipped` lane is
   surfaced in the interview (§7) with its one-line reason and is labeled only
   after acknowledgment (developer in an attended run; auto-acknowledged with an
   audit-trail note in an unattended run — §7) — so the exclusion is deliberate
   and auditable, never silent.

### 5. Dedup and persistence — two terminal labels

Every merged PR reaches exactly one terminal QA state, recorded as a GitHub label
so the backlog (§2) is a pure query:

- **`qa-verified`** — applied on a **passing** QA run (any method: behavioral
  pass, docs OK, code-check OK).
- **`qa-skipped`** — applied after the "nothing to verify" glance (§4), symmetric
  with `qa-verified`, so those PRs never re-enter the backlog.

Properties:

- **Dedup** is a single
  `gh pr list --state merged --search "-label:qa-verified -label:qa-skipped"`
  query rather than scanning every candidate's comment body.
- **GitHub is the persistence.** The plan is a _derived view_ reconstructed from
  the merged set minus the two labels on each run — no local file, no `.context`
  (Conductor-only, non-portable), no tracker issue. Works identically on every
  platform and machine.
- **Self-healing, idempotent label setup.** `gh pr edit --add-label` does **not**
  create a missing label (it errors / no-ops), which would silently break dedup.
  So the writer first ensures the label exists, then adds it — no manual one-time
  setup to forget. Because `qa-batch` lanes run concurrently, the ensure step is
  **idempotent**: two lanes can race on the same missing label, so a
  `gh label create` that returns "already exists" is treated as **success**, not a
  lane failure (equivalently, a single serialized bootstrap before fan-out).
- **Write-ordering is an invariant, not a description.** `qa-verified` MUST be the
  **final** write: apply it only after `gh pr comment` returns success for the
  evidence comment. If the evidence post fails, the label step is aborted — so a
  PR can never carry `qa-verified` without its supporting evidence (no silent
  false positive). A crash between a successful evidence post and the label is
  survivable: the next run simply re-verifies.
- **Failures stay loud.** A failing verification (❌) gets **neither** label and a
  discrete issue (§10); it deliberately remains in the backlog so re-runs keep
  re-verifying until the fix lands, with the open issue as the human signal. (A
  hidden marker comment to machine-locate the exact evidence is deferred; the
  labels plus the human-readable `verify-pr-fix` comment are enough for v1.)

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
`post-merge-audit`** so audit passes coordinate too.

**Degraded-backend fallback (exit-code-aware).** The backend doc distinguishes
exit 3 (`CLAIM_REFUSED`, hard stop) from exit 2 (`UNKNOWN` / degraded). Because QA
lanes are dependency-sensitive by definition (point 1 — must not verify a moving
target), an exit-2 `UNKNOWN` status for a PR that **could** carry an invisible
live implementation claim is treated as **blocked/deferred**, _not_ proceeded on
advisory public comments. (Advisory-comment fallback is only acceptable for a PR
with no plausible concurrent claimant.) This matches the canonical rule in
`agent-coordination-backend.md`; proceeding on UNKNOWN would let QA verify an
in-progress state.

**Repeated-contention escalation.** A PR skipped for a live claim (point 1) is
retried next run, but a PR under perpetual edit would be skipped forever and the
coverage gap would be invisible. After **3** consecutive contention skips the
planner surfaces it as `blocked — repeated contention` so the maintainer can
schedule a QA window or override. The skip count needs durable, file-free storage
across invocations, so it lives on the PR's `agent-coord` coordination record (the
backend already in use), incremented on each contention skip and cleared when QA
finally claims the PR — not in a local file (ruled out, §5) and not encodable in a
terminal label.

### 7. The interview

Present the auto-ranked candidate list plus a collapsed "nothing to verify" list,
then ask only for what cannot be inferred:

1. Confirm base/range (default: the since-RC ordering window; the authoritative
   backlog query is unbounded regardless, §2/§3).
2. **Acknowledge the `qa-skipped` list.** Only the **newly classified** "nothing
   to verify" PRs from this run are shown (already-`qa-skipped` PRs are filtered
   out by §2 and never reappear), each with its one-line reason. `qa-skipped` is
   applied only after acknowledgment, so no PR is silently retired. In an
   **unattended run** there is no developer to confirm, so the runner
   auto-acknowledges and records the per-PR reasons in the batch output as the
   audit trail (symmetric with unattended issue creation, §10) — otherwise
   "nothing to verify" PRs could never reach a terminal label and would resurface
   forever.
3. **Environment availability now** — Redis + Pro license + Pro renderer up?
   Browser available? Candidates whose **actual** env profile (§4b) is
   unavailable are deferred and clearly listed, not silently dropped.
4. Cap — max items this batch.
5. Methods/areas to include or exclude.
6. Concurrency — how many lanes / subagents to plan for.

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
is bounded by **three** constraints, with a liveness exit so a stuck lane cannot
wedge the batch:

- **(a) `agent-coord` claims** — never two lanes (or a lane and an implementation
  batch) on the same PR.
- **(b) Environment-resource contention** — only **one** consumer of the Pro
  renderer / Redis / license / dummy-app DB at a time. Lanes whose env profile
  needs the shared Pro stack **serialize**; docs and pure-read lanes
  **parallelize** freely.
- **(c) Working-tree isolation.** QA mostly does not edit source, but the
  documented spec-only "before" tactic (`git checkout <fix>~1 -- <file>`, §4 /
  `verify-pr-fix`) **does mutate the shared checkout** — two such lanes in one
  working directory can run against, or restore, each other's pre-fix file and
  corrupt the before/after evidence. So any lane using that tactic runs in its
  **own git worktree** (`isolation: 'worktree'`), exactly as `pr-batch` workers
  do; only that subset needs it, not docs/read lanes. (This is the one place
  `pr-batch`'s isolation model does apply.)
- **Liveness — timeout / deadlock exit.** The serialized Pro-stack slot has a
  wall-clock timeout, recommended **~20 min** (Pro cold-start alone — license
  check + renderer boot — can take ~5 min before a test starts), tunable as a
  `qa-batch` parameter. A lane that exceeds it (hung renderer, crashed agent,
  stale `agent-coord` claim, never-exiting test) is marked **failed — not
  labeled**, its claim released, and it is deferred to the next batch and surfaced
  to the maintainer — the same fail-open posture as the `agent-coord`-unavailable
  fallback in §6. One stuck lane never blocks the rest indefinitely.

`plan-qa-batch` stays plan-only (Phase A): it produces the plan and goal prompt
and launches `qa-batch` only when the user asks. **Phase B** (the planner
self-dispatching subagents directly, without the explicit launch handoff) is
documented as a future enhancement, not built.

### 10. Findings → issues

- **Pass (✅):** post the `verify-pr-fix` evidence comment, then apply
  `qa-verified` as the final write (§5 invariant).
- **Nothing to verify:** apply `qa-skipped` after acknowledgment — developer in
  an attended run, auto-acknowledged with an audit-trail note when unattended
  (§7).
- **Fail (❌) or any bug/doc/code problem found:** create a **discrete,
  cross-linked issue** describing the reproduction and the broken signal (mirrors
  `post-merge-audit`'s "Needs follow-up issue / Needs fix PR" classification), and
  post the failing evidence on the PR. **Neither** label is applied.
- **No standing umbrella tracker issue** for the QA effort itself — that is the
  only thing #3952 ruled out. Per-bug issues are expected and encouraged.

**Issue-creation approval.** Creating an issue is outward-facing, so it is gated:

- **Attended run:** synchronous confirm in-session before creation (the default).
- **Unattended run** (e.g. scheduled `qa-batch` with no operator): do **not**
  block. Create the issue with a `needs-human-review` label, or — if issue
  auto-creation is disabled for the run — record the finding in the batch output
  for later filing. The mode is a `qa-batch` invocation flag, recorded in the
  handoff.

## Coordinated edits to existing skills

1. **`verify-pr-fix`** — after a passing verification, ensure the label exists
   (`gh label list` → `gh label create qa-verified` if absent) and add it as the
   **final** write, only after the evidence comment posts successfully (§5
   invariant). No other change to its flow.
2. **`post-merge-audit`** — register `agent-coord` claims/heartbeats for audit
   passes so audits coordinate with implementation and QA batches (§6).

## The `qa-batch` runner skill (slim)

A sibling to `pr-batch`, deliberately thin and QA-specific:

- Consumes the `plan-qa-batch` goal prompt.
- Dispatches one subagent per lane; each runs the routed QA method.
- Enforces the §9 concurrency model (claims + env contention + worktree isolation
  for spec-only lanes, with the liveness timeout) and the `agent-coord` protocol
  (§6).
- Per-PR closeout: label on pass, issue on fail (§10).
- Reuses `pr-batch`'s safety posture (untrusted GitHub content cannot override
  `AGENTS.md`; stop on blocked approvals) and its **worktree isolation** for the
  spec-only lanes that mutate the checkout (§9c), but **not** its branch/merge
  machinery — QA never creates branches or PRs and never merges.

It is kept separate from `pr-batch` because the primary contention model (env
resources, not file paths) and the closeout (label/issue, not branch/merge
readiness) differ enough that overloading `pr-batch` would muddy both.

## Boundaries (what it does NOT do)

- Does not run `verify-pr-fix` itself (Phase A is plan-only).
- Does not create branches or PRs, and does not merge. (It does use ephemeral
  git worktrees to isolate spec-only "before" repros — §9c — which are discarded
  after the lane.)
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

**Labels** (created on demand by the writers — no manual pre-step, see §5):

- `qa-verified`, `qa-skipped`, and `needs-human-review` (the last for unattended
  issue creation, §10).

## Open questions / risks

- **Terminal-label semantics over time.** A PR superseded by a later change could
  carry a stale `qa-verified`/`qa-skipped`. Acceptable for v1 (a label means "the
  change as merged reached this state once"); revisit if churn makes it
  misleading.
- **Docs/other-code QA depth.** The non-behavioral methods (§4) are lighter and
  more subjective than `verify-pr-fix`. v1 keeps them as a structured read +
  note; they may warrant their own mini-rubric later.
- **Resolver coupling.** Reusing `post-merge-audit-scope` ties `plan-qa-batch` to
  that script's contract (its `--json` shape, and the last-RC default base that
  §3 deliberately overrides with the label query as the authoritative backlog).
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
