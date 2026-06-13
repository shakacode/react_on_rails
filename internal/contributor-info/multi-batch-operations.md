# Multi-Batch Operations

Use this playbook when one coordinator is running multiple agent batches across
machines, launch surfaces, or repositories. It sits above the per-lane workflow
rules in [AGENTS.md](../../AGENTS.md),
[PR Batch Skills Usage](agent-pr-batch-skills.md), and
[Agent Coordination Backend](agent-coordination-backend.md).

The goal is to make the live operating model reconstructable by a cold-start
reader without asking the coordinator which machine, tool, or repository owns a
lane.

## Baseline Topology

The current coordination model assumes these durable host and surface roles.
Keep specific hardware inventory in the private operations runbook and update
that inventory when the active machine pool or launch surfaces change:

| Surface or host              | Primary role                  | Notes                                                                                       |
| ---------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------- |
| Mobile high-memory host      | High-memory mobile batch host | Useful for heavy local context, but treat power, network, and travel as availability risks. |
| Stable wired host            | Stable wired batch host       | Prefer for long-running desktop sessions and lanes that benefit from steady network/power.  |
| Claude Desktop               | Batch kickoff surface         | Best for long-running multi-lane work when Claude Fable should own the hardest items.       |
| Codex Desktop                | Batch kickoff surface         | Best for long-running Codex batches, local validation, commits, and repo-aware finishing.   |
| conductor.build              | Single-PR focus and finishing | Best when one PR needs concentrated Claude plus Codex chats on the same PR.                 |
| shakacode/react_on_rails     | Main gem/npm/Pro monorepo     | Claims use this full repo name in the coordination backend.                                 |
| shakacode/react_on_rails_rsc | RSC integration/adoption repo | Uses the same coordination backend, with claims namespaced by repo.                         |

Run up to three concurrent batches only when their packages, branches, and risk
surfaces are intentionally disjoint:

- one Claude Fable batch for the hardest, most ambiguous, or highest-risk items;
- two Codex batches for simpler, parallel-friendly, well-scoped items;
- conductor.build sessions only for focused PR finishing or a single PR that
  needs both Claude and Codex attention.

Machine choice is an operational decision, not a policy label. Prefer the wired
host when continuity matters more than local memory, and prefer the mobile host
when mobility or local capacity is the better fit. If either machine is likely
to disappear during a lane, route dependency-sensitive work elsewhere.

## Launcher Roles

Use Claude Desktop and Codex Desktop to kick off batches because they are the
right surfaces for long-running lane splits, local worktrees, validation loops,
and coordinator handoffs.

Use conductor.build for one PR at a time. Its special value is focused finishing:
Claude and Codex chats can work against the same PR context. A conductor session
must take a normal coordination lease before editing or finishing that PR. Once
the lease exists, batch workers must skip that PR unless the lease is released,
dead, or explicitly transferred by the coordinator.

Do not let conductor become an invisible side channel. If conductor takes a PR,
record the claim in shakacode/agent-coordination with the same repo and target
identity that batch workers use, then refresh heartbeats while conductor owns
the lane.

## Coordination Lifecycle

The private shakacode/agent-coordination repository is the coordination source
of truth for concurrent batches. Public issue or PR claim comments are human
hints and recovery aids only.

Use stable agent ids with the base format `<machine>-<tool>-<batch>`, for
example `mobile-codex-batch2`, `desktop-claude-fable`, or `desktop-conductor-finish`. If one
batch runs multiple simultaneously-heartbeating lanes on the same machine and
tool, add a short lane suffix after the batch id so each heartbeat remains
distinguishable.

Use this lifecycle for every lane:

1. **Kickoff**: the coordinator runs `agent-coord status`, confirms the target
   repo, and chooses non-overlapping lane owners.
2. **Claim**: the lane owner takes an `agent-coord claim` for the repo and
   issue/PR target before creating a branch, worktree, or conductor session.
3. **Heartbeat**: the owner sends `agent-coord heartbeat` at every phase
   transition: item start, branch update, PR update, review pass, blocked state,
   resumed state, and done state.
4. **Status**: the coordinator checks `agent-coord status` before starting
   dependency-sensitive work, rebasing, pushing, finishing, or reassigning a
   target.
5. **Blocked**: the owner records the blocker in coordination state and stops
   speculative work on that lane. The coordinator assigns exactly one owner for
   the shared question or fix.
6. **Closeout**: the owner marks the lane done, including final branch/PR state
   and validation evidence, then releases or lets the claim expire according to
   the backend policy.

If the private backend is unavailable, use the structured public claim comment
fallback from
[pr-processing.md](../../.agents/workflows/pr-processing.md#coordination-state),
but do not use a public comment to override a refused private claim.

## Batch Sizing And Routing

The per-batch cap remains in
[PR Batch Skills Usage](agent-pr-batch-skills.md): 8 items when files or risk
overlap, or 10 fully independent items. Treat that as a per-batch maximum, not a
global promise that three batches can safely process 24 to 30 active items.

Before launching multiple batches, route by package and risk:

- Avoid running two batches against the same package or high-churn directory at
  the same time. Examples include `react_on_rails/`,
  `packages/react-on-rails/`, `react_on_rails_pro/`, and an adopter repo such
  as `react_on_rails_rsc`.
- Route all `react_on_rails_pro/` work to one batch unless the coordinator has
  explicit disjoint file ownership and validation coverage for each lane.
- Keep Pro/core boundary work in one batch when a change crosses OSS gem code,
  Pro code, package build config, SSR, hydration, or release-sensitive behavior.
- Route RSC-sensitive work intentionally. If work spans `react_on_rails` and
  `react_on_rails_rsc`, either keep it in one coordinated batch or designate one
  repo as the lead and make the other repo wait on a claim/status dependency.
- Use conductor.build to remove one PR from the batch pool when finishing needs
  concentrated review, conflict resolution, or Claude plus Codex context on the
  same PR.

Cross-batch safety should reduce concurrency before it reduces review quality.
If two batches want the same package, move one target, shrink one batch, or make
one batch wait for the other lane's done heartbeat.

## Failure Drills

### Mobile Batch Host Goes Offline

1. Check `agent-coord status` for the affected lane.
2. If the heartbeat is still live, do not take over. Wait or contact the
   operator through the coordinator channel.
3. If the heartbeat is stale, pause dependent work and avoid starting new lanes
   in the same package.
4. If the heartbeat is dead, a replacement worker may claim the target only
   after checking the branch/PR state and recording the takeover in coordination
   status. With the default 15-minute TTL, expect up to 60 minutes from the last
   heartbeat before liveness reaches `dead`.
5. If local unpushed work may exist on the laptop, mark the lane blocked instead
   of recreating a competing implementation.

### Stable Desktop Session Dies

1. Restart the desktop app or terminal on the same machine when practical.
2. Reuse the same agent id for the same lane so the coordinator can connect the
   resumed heartbeat to the prior work.
3. Re-read `git status`, current branch, and remote branch state before editing.
4. If the session cannot be recovered, mark the heartbeat stale/dead through the
   normal TTL path and let a replacement worker take a fresh claim.

### Conductor Takes A PR

1. The conductor operator claims the PR target before editing.
2. The active batch coordinator reruns status and removes that PR from worker
   assignment.
3. Any worker that already started the PR stops, reports its branch/worktree
   state, and waits for an explicit handoff.
4. When conductor finishes, it records validation evidence and either marks the
   lane done or transfers ownership back to a batch worker.

### Two Batches Find A Shared Blocker

1. Stop speculative fixes in every affected lane.
2. Record one shared blocker in coordination status with affected repo/target
   ids.
3. Assign one owner to investigate or ask the maintainer question.
4. Keep unaffected lanes moving only if they do not touch the blocked package,
   branch, or release gate.
5. Resume affected lanes only after the blocker is answered, fixed, or
   explicitly waived.

## Cross-Repo Operation

Adopting repos join the same private shakacode/agent-coordination backend.
Claims and heartbeats are namespaced by full repo name, so
`shakacode/react_on_rails#3973` and `shakacode/react_on_rails_rsc#3973` are
different targets even if the issue numbers match.

Use one status table for the whole operating window. That lets a coordinator see
that a `react_on_rails_rsc` lane is waiting on a `react_on_rails` package
release, or that a conductor session has removed a PR from the shared pool.

When a cross-repo change needs sequencing, make the dependency explicit in the
coordination state:

- lead repo and target;
- dependent repo and target;
- current owner and heartbeat liveness;
- unblock condition, such as merged PR, published package, released RC, or
  maintainer decision.

## Operator Checklist

Before kickoff:

- confirm exact issue/PR targets and trusted scope;
- run `agent-coord status`;
- assign agent ids using `<machine>-<tool>-<batch>`;
- route packages so concurrent batches do not overlap;
- reserve conductor.build only for single-PR focus or finishing;
- document any cross-repo dependency before workers start.

During execution:

- refresh heartbeats at phase transitions;
- check status before dependency-sensitive work, rebase, push, or closeout;
- shrink or pause batches when package overlap appears;
- treat public claim comments as advisory only.

At closeout:

- record final branch/PR state and validation evidence;
- mark blocked lanes with exact blocker ownership;
- check both `react_on_rails` and `react_on_rails_rsc` status when work crossed
  repositories;
- hand off remaining risks with `UNKNOWN` for anything not verified live.
