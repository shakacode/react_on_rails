# Batch Plan

## Objective

Fix P1 error redaction in PPR diagnostics: ensure no PPR notification payload
or log line can carry unredacted request-derived error content. Close the
remaining acceptance criteria items (P2, follow-ups) with documented
investigation findings.

## Repository

`shakacode/react_on_rails`

## Batch title

ROR 09-01 13:10 - PPR error redaction

## Included items

- **Issue #4966**: [PPR v1: harden the diagnostics surface](https://github.com/shakacode/react_on_rails/issues/4966) — OPEN, assigned AbanoubGhadban, labels P1/enhancement/roadmap:17x/theme:performance. Single PR targeting `ppr-integration`.

### Scope reduction (from investigation)

The issue lists 6 acceptance criteria. Our deep investigation (see
`plans/detailed-investigation-report.md`) found that only 1 requires a code PR:

| AC item | Verdict | Action |
|---|---|---|
| P1: Error redaction in notifications/logs | **REAL — fix needed** | PR |
| P1: Unbounded cache-read log | **REAL — fix needed** | PR (same PR) |
| P2: Settle budget bounds async render | Overstated; `ssr_timeout` safety net | Close with findings |
| FOUC visreg gate | Already fully implemented | Close as done |
| Ruby specs for #4897 | Nice-to-have, not blocking | Close as declined |
| Href normalization | Not a real problem | Close as declined |

## Excluded or deferred

- P2 settle budget: `ssr_timeout` (5s) already prevents hangs; streaming path
  has same gap; realistic risk is low. Declined with reasoning.
- FOUC visreg gate: Already implemented (ShakaPerf + 446 lines Playwright E2E +
  system spec). No work needed.
- Ruby specs for #4897: JS tests cover end-to-end; failure mode is graceful
  degradation. Declined as nice-to-have.
- Href normalization: Not a real problem — exact string comparison is correct
  because both phases read from same `loadable-stats.json`. Declined.

## File-touch map and path evidence

Single-target serial batch. No collision possible. Paths from investigation:

| Path | Change type | Owner |
|---|---|---|
| `react_on_rails_pro/lib/react_on_rails_pro/ppr.rb` | Edit | lane-1 |
| `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb` | Edit | lane-1 |
| `react_on_rails/lib/react_on_rails/prerender_error.rb` | Edit | lane-1 |
| `react_on_rails_pro/spec/` (new regression specs) | Create | lane-1 |

## Dependencies and sequencing

None. Single lane, no cross-dependencies.

## Subagent split

Single lane `lane-1`: P1 error redaction PR.

### lane-1: PPR error redaction

**Goal:** Redact error content in PPR diagnostics before publishing to
AS::Notifications and logs.

**Changes:**
1. `ppr.rb` `safe_error_summary` → publish `error.class.name` + redacted
   summary (no raw `error.message`)
2. `react_on_rails_pro_helper.rb` `ppr_sanitize_for_log` → same redaction
3. `react_on_rails_pro_helper.rb` line 1388 → bound + sanitize unbounded
   cache-read warn
4. `react_on_rails_pro_helper.rb` lines 1617, 1820, 1841 → bound all other
   unbounded `e.message` log sites
5. `prerender_error.rb` → add `console_messages` to `SENSITIVE_CONTEXT_KEYS` or
   redact in `#message`
6. Regression specs for each of the three notification events
   (`ppr.resume.degraded_pre_flush`, `ppr.resume.degraded_post_flush`,
   `ppr.cache.read_error`)

**Done when:** No PPR notification payload or log line carries unredacted
request-derived error content; regression specs pass; PR targets
`ppr-integration`; `ask` merge authority satisfied.

## Coordinator model/effort preference

Opus 5/high (default single-target planner, claude-profile v1).

Host: Claude Code. Model: Opus 5. Effort: UNKNOWN (not host-exposed).

## Worker model/effort preferences

- Initial: Sonnet 5/high → lane-1 (well-scoped Ruby changes, clear acceptance
  criteria, bounded file surface). Rationale: fix pattern is known (reuse #4597
  redaction approach), 4 files, no design ambiguity.
- Escalation: Opus 5/high after MODEL_ESCALATION_REQUEST; max 1.

## Batch manifest provenance

- `pack_sha`: UNKNOWN (no agent-workflows checkout verified)
- `coordinator_preference`: Opus 5/high
- Lanes: `lane-1:fork+Sonnet 5/high+Claude Code/UNKNOWN/UNKNOWN`
- Registration: coordination backend unavailable (`agent-coord` not installed);
  durable handoff in this Batch Plan.

## Batch size target

`claude`; wave: 1/1 (single target, serial).

## Planning-chat role

`prompt-only`

## Retained responsibilities

None.

## Launch mode

`same-thread` — continue in the current chat as the batch coordinator after
user approves the goal prompt.

## merge_authority

`ask`

## Concurrent activity and dependency status

- Coordination backend: unavailable (`agent-coord` not installed). Status: UNKNOWN.
- No existing PRs for #4966.
- Parent issue #3571 (Track B) is the umbrella; siblings #4888, #4890, #4891,
  #4896, #4897 all landed on `ppr-integration`.

## Coordination hooks

- Backend claim exclusions: UNKNOWN (backend unavailable)
- Public claim-comment fallback: not needed (single operator, `same-thread`)

## Batch QA Lane

Not required. Rationale: single-target Ruby-only change with clear regression
specs in the acceptance criteria; the fix pattern is established (#4597); no
user-visible UI change; no bundle/asset impact. QA is embedded in the lane's
"Done when" (regression specs for all 3 notification events).

## Stage dependency plan

Single independent lane, no edges.

```json
{
  "plan_id": "ror-4966-redact-v1",
  "lanes": [
    {"lane_id": "lane-1", "target": "issue:4966", "type": "implementation"}
  ],
  "edges": []
}
```

Live replay: `edges: []` — no gated actions. Critical path: `lane-1` only.

- `STAGE_DEPENDENCY_PLAN_PATH`: inline (single-lane, no file needed)
- `STAGE_DEPENDENCY_PLAN_ID`: `ror-4966-redact-v1`

## Verification expectations

- Regression specs for `ppr.resume.degraded_pre_flush`,
  `ppr.resume.degraded_post_flush`, `ppr.cache.read_error` — each asserts
  payload `:error` key contains class name, not raw message
- Existing PPR specs continue to pass
- JS tests unaffected (Ruby-only change)
- CI green on `ppr-integration`

## Expected readiness states

- PR created targeting `ppr-integration`: `ready-for-review`
- CI: `waiting-on-checks-or-review` until green
- Review: `waiting-on-checks-or-review` until `claude-review` or maintainer approval
- Merge: `ask` — walk through diff, then merge decision

## Prompt sizing

See generated goal prompt below.

## Open questions

None — scope is clear from investigation.
