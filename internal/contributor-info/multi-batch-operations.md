# Multi-Batch Operations

Use this playbook when one coordinator is running multiple agent batches across
machines, launch surfaces, or repositories. It sits above the per-lane workflow
rules in [AGENTS.md](../../AGENTS.md),
[PR Batch Skills Usage](agent-pr-batch-skills.md), and
[Agent Coordination Backend](agent-coordination-backend.md).

The goal is to make the live operating model reconstructable by a cold-start
reader without asking the coordinator which machine, tool, or repository owns a
lane.

## Fresh Machine Quick Start

Use this when a coordinator asks Codex, Claude, or conductor.build to join a
batch from another machine or fresh checkout.

The coordinator should provide the batch objective, exact targets, stable
`batch_id`, lane names, agent ids, any `depends_on` refs, and whether the worker
should use this PR branch or `main` for the current workflow docs.

1. Authenticate GitHub and confirm access:

   ```bash
   gh auth status
   gh repo view shakacode/react_on_rails
   gh repo view shakacode/agent-coordination
   ```

2. Check out the public repo branch that contains the active workflow docs,
   normally `main` after the workflow docs land or the active PR branch while it
   is still open.
3. Clone or update the `agent-coord` CLI/bootstrap source and put
   `agent-coord` on `PATH`:

   ```bash
   gh repo clone shakacode/agent-coordination
   cd agent-coordination
   bundle install
   .agents/bin/test
   .agents/bin/validate
   bin/agent-coord --help
   bin/agent-coord bootstrap
   export PATH="$HOME/.local/bin:$PATH"
   hash -r 2>/dev/null || true
   command -v agent-coord || which agent-coord
   : "${AGENT_COORD_API_URL:?load the private HTTP backend URL before continuing}"
   : "${AGENT_COORD_API_TOKEN:?load this machine's private HTTP backend token before continuing}"
   unset AGENT_COORD_BACKEND AGENT_COORD_REF AGENT_COORD_STATE_ROOT AGENT_COORD_STATUS_STATE_ROOT
   agent-coord doctor --json
   agent-coord config show --json
   agent-coord status --batch-id <batch-id> --json
   ```

   The remaining snippets assume that `PATH` entry is present in the active
   shell. In another shell, add the export first or replace each `agent-coord`
   command below with `"$HOME/.local/bin/agent-coord"`.

4. If `doctor --json` fails, or targeted status exits non-zero (exit 2 means
   degraded/UNKNOWN) or times out, report private state as `UNKNOWN` and use the
   structured public claim comment fallback where dependency rules allow it. Do
   not start a dependency-sensitive lane when the lane declares `depends_on` and
   private status cannot be checked.
5. Before dependent lanes start, the coordinator creates or updates batch state
   in the private `agent-coord` backend so targeted batch status can render
   `blocked_on` refs.
6. Each worker claims before creating a worktree, branch, or conductor session:

   ```bash
   agent-coord claim \
     --agent-id <agent-id> \
     --repo shakacode/react_on_rails \
     --target <issue-or-pr> \
     --batch-id <batch-id> \
     --branch <branch>
   ```

   A refused claim after successful status exits with `CLAIM_REFUSED` / code 3
   and is a hard stop. Report the holder, heartbeat liveness, and target instead
   of creating competing work. Operational failures are `UNKNOWN`, not claim
   overrides.

7. Each worker heartbeats at item start, branch/PR update, review pass, blocked
   state, resumed state, and done state:

   ```bash
   agent-coord heartbeat \
     --agent-id <agent-id> \
     --repo shakacode/react_on_rails \
     --target <issue-or-pr> \
     --batch-id <batch-id> \
     --branch <branch> \
     --status in_progress
   ```

8. Before rebase, push, readiness, or closeout, rerun
   `agent-coord status --batch-id <batch-id> --json`. If a lane shows non-empty
   `blocked_on`, set the worker heartbeat to `--status blocked`, report the
   blocked refs, and move to independent work.
9. Final handoff from the second machine must include the agent id, batch id,
   branch/PR URL, validation run, current
   `agent-coord status --batch-id <batch-id> --json` summary, blockers, and
   `UNKNOWN` for anything not verified live.

## Baseline Topology

The current coordination model uses these role names for multi-machine,
multi-launcher operating windows. Keep specific hardware inventory, active
inbox ids, and capacity counts in runtime registration or the private operations
runbook; this public table is role vocabulary, not a durable list of machine
names or an enforced scheduler policy:

| Role                         | Primary use                   | Notes                                                                                                |
| ---------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| Mobile high-memory host      | High-memory batch host        | Useful for heavy local context, but treat power, network, and travel as availability risks.          |
| Stable wired host            | Stable batch host             | Prefer for long-running desktop sessions and lanes that benefit from steady network/power.           |
| Claude Desktop               | Batch kickoff surface         | Best for long-running multi-lane work when a configured high-capability lane owns the hardest items. |
| Codex Desktop                | Batch kickoff surface         | Best for long-running Codex batches, local validation, commits, and repo-aware finishing.            |
| conductor.build              | Single-PR focus and finishing | Best when one PR needs concentrated Claude plus Codex chats on the same PR.                          |
| shakacode/react_on_rails     | Main gem/npm/Pro monorepo     | Claims use this full repo name in the coordination backend.                                          |
| shakacode/react_on_rails_rsc | RSC integration/adoption repo | Uses the same coordination backend, with claims namespaced by repo.                                  |

Prefer no more concurrent batches than the registered capacity profiles expose
as available lane slots. A manual override beyond profile-advertised capacity
requires an explicit human decision with package and risk separation recorded in
the batch handoff. Keep concurrent batch packages, branches, and risk surfaces
intentionally disjoint:

- route the hardest, most ambiguous, or highest-risk items to a configured
  high-capability lane;
- route simpler, parallel-friendly, well-scoped items to remaining available
  capacity;
- conductor.build sessions only for focused PR finishing or a single PR that
  needs both Claude and Codex attention.

Machine choice is an operational decision, not a policy label. Prefer the wired
host when continuity matters more than local memory, and prefer the mobile host
when mobility or local capacity is the better fit. If either machine is likely
to disappear during a lane, route dependency-sensitive work elsewhere. If a
coordinator exceeds registered capacity, record the package/risk separation in
the batch handoff and downgrade any uncertain overlap to blocked or deferred
work.

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
record the claim in the private `agent-coord` state backend with the same repo
and target identity that batch workers use, then refresh heartbeats while
conductor owns the lane. If `agent-coord` is not installed in the conductor
environment, install it with the CLI bootstrap first or use the structured
public claim comment fallback until the host is configured; do not treat an
unbootstrapped conductor session as a private claim override.

## Coordination Lifecycle

The private `agent-coord` state backend reported by
`agent-coord config show --json` is the coordination source of truth for
concurrent batches. Public issue or PR claim comments are human hints and
recovery aids only.

Use stable agent ids with the base format `<machine-or-profile>-<batch>-<lane>`,
for example `mobile-batch2-lane1`, `desktop-highcap-lane1`, or
`desktop-conductor-lane1`; if one batch runs multiple
simultaneously-heartbeating lanes on the same machine or profile, add a short
lane suffix after the batch id so each heartbeat remains distinguishable.
Existing registrations using the older `<machine>-<tool>-<batch>` format remain
valid while their old claim or heartbeat is live. A restarted worker must keep
using the old id until that claim is released or expired; re-key only for new
lanes or after the old claim is gone.

Use this lifecycle for every lane:

1. **Kickoff**: the coordinator runs targeted status when a batch id or target
   is known, confirms the target repo, and chooses non-overlapping lane owners.
   If no batch id or target is known yet, run `agent-coord doctor --json` to
   confirm backend health, then assign targets or a batch id before any status
   read. Broad `agent-coord status` is audit-only.
2. **Claim**: the lane owner takes an `agent-coord claim` for the repo and
   issue/PR target before creating a branch, worktree, or conductor session.
3. **Heartbeat**: the owner sends `agent-coord heartbeat` at every phase
   transition: item start, branch update, PR update, review pass, blocked state,
   resumed state, and done state.
4. **Status**: the coordinator checks
   `agent-coord status --batch-id <batch-id> --json` before starting
   dependency-sensitive work, rebasing, pushing, finishing, or reassigning a
   target.
5. **Blocked**: the owner records the blocker in coordination state and stops
   speculative work on that lane. The coordinator assigns exactly one owner for
   the shared question or fix.
6. **Closeout**: the owner marks the lane done, including final branch/PR state
   and validation evidence, then releases or lets the claim expire according to
   the backend policy.

If the private `agent-coord` state backend is unavailable, use the structured
public claim comment fallback from
[pr-processing.md](../../.agents/workflows/pr-processing.md#coordination-state),
but do not use a public comment to override a refused private claim.

## Batch Sizing And Routing

The per-batch cap remains in
[PR Batch Skills Usage](agent-pr-batch-skills.md): 8 items when files or risk
overlap, or 10 fully independent items. Treat that as a per-batch maximum, not a
global multiplier based on a presumed lane count.

For whole-surface triage, derive the number of implementation groups from
registered capacity profiles and enabled inboxes. The flow is:

1. Read live `agent-coord` claims and heartbeats.
2. Read runtime capacity profiles and inbox config from the private
   `agent-coord` state backend or a gitignored local config file.
3. Convert the registered profiles into lane slots, bound the total by enabled
   inboxes, then subtract the unique occupied/reserved lane-ref set. That set
   includes live in-progress lanes, live blocked lanes, blocked lanes without a
   live heartbeat, and reserved lanes. If lane refs, heartbeat liveness, blocked
   state, reserved state, profiles, or inbox config cannot be verified, stop
   phase 2 with a precise blocker instead of deriving a group count.
4. If the subtraction result is negative, report "occupied/reserved lanes exceed
   registered capacity" with the bounded slot count and occupied lane refs, then
   stop phase 2 instead of clamping or inventing groups.
5. If no lane slots remain while actionable work remains, report "all lanes
   currently occupied" and stop phase 2 instead of inventing groups.
6. Split the current wave into up to one non-empty group per available lane slot,
   capped by the per-batch limits above. When actionable work exceeds the capped
   current wave, report the remaining backlog/next wave; when capacity exceeds
   actionable work, report idle slots separately.
7. Write assigned-but-not-started work to the per-inbox queues when the backend
   supports queue state. Queue state is advisory; if it is unsupported, omit the
   queue summary and note that queue state is unavailable.

The queue is not a lock. Workers still claim the repo target before editing, and
the queue view must reconcile live claims, stale heartbeats, released claims,
and done heartbeats before recommending the next item for an inbox.

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

1. Check targeted `agent-coord status --repo shakacode/react_on_rails --target <issue-or-pr> --json`
   or `agent-coord status --batch-id <batch-id> --json` for the affected lane.
2. If the heartbeat is still live, do not take over. Wait or contact the
   operator through the coordinator channel.
3. If the heartbeat is stale, pause dependent work and avoid starting new lanes
   in the same package.
4. If the heartbeat is dead, a replacement worker may claim the target only
   after checking the branch/PR state and recording the takeover in coordination
   status. Use `agent-coord config show --json`, the backend schema, and CLI help
   for the current TTL and dead-threshold calculation.
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

Adopting repos join the same private `agent-coord` state backend. Claims and
heartbeats are namespaced by full repo name, so
`shakacode/react_on_rails#3973` and `shakacode/react_on_rails_rsc#3973` are
different targets even if the issue numbers match.

Use one desktop project or worktree per repository for code edits. A coordinator
session may read shared `agent-coord` status across repositories, but editing,
validation, commits, and PR updates should happen from the checkout for the
target repo. Cross-repo work is coordinated through backend dependencies rather
than by treating one repo-scoped session as if it owned another repo's files.

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
- run targeted `agent-coord status --repo <repo> --target <issue-or-pr> --json`
  for each exact target before routing, then
  `agent-coord status --batch-id <batch-id> --json` for dependency lanes;
- assign agent ids using `<machine-or-profile>-<batch>-<lane>`;
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
