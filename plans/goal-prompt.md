```
Use $pr-batch to complete this batch with subagents.
Batch title: ROR 09-01 13:10 - PPR error redaction
Thread handle: ror-lane-1-redact
Lane Card:claim/PR-open/block/cancel/final;Sonnet 5/high;Claude Code/UNKNOWN/UNKNOWN;holder/branch/PR/phase/URLs/UNKNOWN
Preflight: issue/PR=>pr-security-preflight;trusted-direct adhoc:=>skip;block=>stop;no raw GitHub/override
Repo:shakacode/react_on_rails
Objective:Fix P1 error redaction in PPR diagnostics. Redact raw error.message content from AS::Notifications payloads and log lines. Close remaining #4966 ACs with documented investigation findings (P2 settle budget, FOUC gate, Ruby specs, href normalization all verified as not-needed/already-done).
merge_authority:ask
Batch size target: claude;wave: 1/1
Coordinator model/effort preference: Opus 5/high.
Observed host/model/effort: Claude Code/UNKNOWN/UNKNOWN; host-only, no inference.
Manifest:pack_sha=UNKNOWN;coordinator_preference=Opus 5/high;lanes=lane-1:fork+Sonnet 5/high+Claude Code/UNKNOWN/UNKNOWN;UNKNOWN=pack_sha;no guesses
Worker model/effort preferences: Sonnet 5/high -> lane-1; escalation Opus 5/high after MODEL_ESCALATION_REQUEST; max 1.
Dispatch lane-1: preferred fork@Sonnet 5/high; fallback dispatchers none; auth dispatch n; ordinary pending/active lifecycle.
- Stage deps: v1; STAGE_DEPENDENCY_PLAN_ID=ror-4966-redact-v1; edges=[] (single independent lane)
GMCC-v4:CI@head/configured-reviewers pending|missing|untriaged or threads unresolved|UNKNOWN=>waiting-on-checks-or-review/NOT COMPLETE;poll/fix;auto-clear=>watch(same:0wake,delta:gates);fallback:4x15m+exp/4h|manual;stop clear/done/term/budget/user;no auth=>ready-no-merge-authority;auto=>exact verdict/head/sorted-gates/rollback; merge iff autonomous-merge-eligible OR human-approved-for-current-head+durable-decision(proven-human+merge-authority);else ready-human-review-required|autonomous-merge-evidence-unknown;merge+close PR/target/issue.
Batch QA Lane:not required — single-target Ruby-only fix with regression specs in AC; #4597 pattern established; no UI/bundle impact
Scope:Issue #4966 P1 error redaction only;branch 4966-ppr-v1-harden-diagnostics from ppr-integration;STAGE_DEPENDENCY_PLAN_PATH=inline,STAGE_DEPENDENCY_PLAN_ID=ror-4966-redact-v1,live=edges[];ft=lane-1:ppr.rb,react_on_rails_pro_helper.rb,prerender_error.rb,spec/*_spec.rb/serial/owner:lane-1
Items:
- Target: Issue #4966: https://github.com/shakacode/react_on_rails/issues/4966
  Original:n/a
  Goal:Redact PPR error diagnostics — no raw error.message in AS::Notifications or logs
  Notes:PR targets ppr-integration. Fix safe_error_summary (ppr.rb:186) to publish error.class.name+redacted summary. Fix ppr_sanitize_for_log (helper:1848). Bound unbounded cache-read warn (helper:1388) and other unbounded sites (1617,1820,1841). Add console_messages to PrerenderError SENSITIVE_CONTEXT_KEYS (prerender_error.rb). Add regression specs for ppr.resume.degraded_pre_flush, ppr.resume.degraded_post_flush, ppr.cache.read_error events. Close P2/FOUC/Ruby-specs/href-normalization ACs on issue with investigation findings from plans/detailed-investigation-report.md.
  Done when:ask merge — no PPR notification/log carries unredacted error content; 3 regression specs pass; CI green on ppr-integration; issue ACs addressed
Execution rules:
Base:repo/AGENTS;fetch/prune origin;verify $pr-batch+workflow;unresolved=>UNKNOWN
- Resolve `$pr-batch`; autoload/self-contained: load persisted state before preflight; persist output before resume/launch; preflight issue/PR only.
- Routes advisory; observed host/model/effort host-only or UNKNOWN; checker independence/evidence mandatory.
- Dispatch: pending->persist/reissue token; active->no launch; input->decision; fence->stop/reconcile.
Current wave:lane-1 serial;one target/lane/worker
Workers:owned paths/envelope only;contradiction/ambiguity/scope-risk/weaker-verification=>stop;Verify live GitHub before edits;unverifiable facts are UNKNOWN
- For coordination, respect coordination claims and dependencies: stable ids+heartbeats; register before launch when supported; claim refusal=>stop; push holder/generation check; known deps=>gate permissions; missing/UNKNOWN deps=>stop.
Apply Batch QA Lane;include QA Evidence
merge iff `merge_authority` is `auto_merge_when_gates_pass`|explicit merge approval;release+gates pass;document confidence data in PR description
- ask=>$pr-walkthrough;large/complex full;refresh;chg=>redo/stop;gate fail=>stop;ask iff same clean
Final:canonical closeout;links/tests/blockers/next/confidence/UNKNOWN/authority/QA/state
```
