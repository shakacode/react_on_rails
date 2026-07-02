# Release Verification Runbook (Behavioral Lanes)

Behavioral verification for a release candidate: the failure modes that unit CI, static review,
and the [`rc-testing-plan.md`](rc-testing-plan.md) fleet smoke gates are structurally blind to —
broken upgrade paths, debut-feature edge cases, resource leaks under sustained load, and
published-artifact defects.

This runbook complements, and does not replace, the canonical gates:

- [`rc-testing-plan.md`](rc-testing-plan.md) — hard-gate model, fleet bump PRs, tracking-issue
  lifecycle, report template, waivers. Lane reports from this runbook are posted to the same RC
  tracking issue.
- [`release-train-runbook.md`](release-train-runbook.md) — branch/tag mechanics. These lanes run
  during phase 2 (stabilize) and must be green (or explicitly waived) before phase 4 (promote).

Each lane below is a **self-contained agent prompt**: fill the parameters, paste the prompt into a
fresh agent session (Claude or Codex) with repo access, and collect the report. Lanes are
independent — run them in parallel. Origin: post–2026-06-12 review retro
([#4346](https://github.com/shakacode/react_on_rails/issues/4346)), where diff review found the
bugs it could find and these lanes cover what it could not.

## Parameters

Fill once per RC; every prompt references these placeholders.

| Placeholder           | Meaning                                                        | Example (17.0.0)                                |
| --------------------- | -------------------------------------------------------------- | ----------------------------------------------- |
| `{{PREV_STABLE}}`     | Last stable git tag (upgrade baseline)                         | `v16.6.0`                                       |
| `{{RC_TAG}}`          | RC under verification                                          | `v17.0.0.rc.7`                                  |
| `{{RELEASE_BRANCH}}`  | Ephemeral release branch                                       | `release/17.0.0`                                |
| `{{TRACKING_ISSUE}}`  | RC tracking issue (per rc-testing-plan lifecycle)              | —                                               |
| `{{UPGRADE_APP_OSS}}` | Fleet app on `{{PREV_STABLE}}` for the OSS upgrade dry-run     | `shakacode/react-webpack-rails-tutorial`        |
| `{{UPGRADE_APP_PRO}}` | Fleet app with Pro + RSC/streaming for the Pro upgrade dry-run | `shakacode/react-on-rails-demo-hacker-news-rsc` |
| `{{RSC_VERSION}}`     | react-on-rails-rsc version this release line pins              | `19.2.1`                                        |

Re-run policy: a new RC with runtime changes re-runs Lanes 2–4 for the affected surfaces and Lane 1
if upgrade-relevant files changed (generators, install templates, config, docs/upgrade). A
version/changelog-metadata-only RC re-runs Lane 4a only.

## Lane 0 — Release inventory (feeds Lanes 2 and 4)

Cheap, run first. Produces the debut-feature list and breaking-change list the other lanes consume.

**Prompt:**

```text
You are preparing the verification inventory for react_on_rails {{RC_TAG}} (previous stable
{{PREV_STABLE}}). Work in a clean checkout of shakacode/react_on_rails at {{RC_TAG}}. Read-only.

1. Compute the release diff: `git log --oneline {{PREV_STABLE}}..{{RC_TAG}}` and
   `git diff --stat {{PREV_STABLE}} {{RC_TAG}}` scoped to shipping surfaces only:
   react_on_rails/lib, react_on_rails_pro/lib, react_on_rails_pro/app,
   packages/react-on-rails/src, packages/react-on-rails-pro/src,
   packages/react-on-rails-pro-node-renderer/src, and generator templates.
2. Read the CHANGELOG.md sections covering {{PREV_STABLE}}..{{RC_TAG}}.
3. Produce three lists, each entry with PRs, files, and doc links:
   a. DEBUT FEATURES — user-facing capabilities new in this release (new APIs, options,
      helpers, generator behavior, protocol changes). For each: the contract as documented,
      the surfaces it touches (Ruby / npm / renderer / generated app), and its opt-in state
      (default-on vs flag/config-gated).
   b. BREAKING CHANGES — anything that changes behavior for an app upgrading from
      {{PREV_STABLE}}, whether or not the CHANGELOG labels it breaking. Derive from the diff,
      not only from the CHANGELOG (removed/renamed public methods, changed defaults, raised
      minimums, changed generated output).
   c. DEPENDENCY LINE CHANGES — runtime dependency lines that moved (e.g. react-on-rails-rsc,
      React peer ranges, Node/Ruby minimums).
4. Flag any item in (b) that is absent from the CHANGELOG — these become Lane 4a findings.

Output: a single markdown report with the three lists, ranked by user impact. No prose padding.
This report is pasted into the Lane 2 and Lane 4a prompts, so keep entries self-contained.
```

**Pass criteria:** none (inventory). Post the report to `{{TRACKING_ISSUE}}`.

## Lane 1 — Migration-guide-driven upgrade dry-run

Distinct from the fleet RC bump PRs in rc-testing-plan.md: those bump apps already tracking the RC
line. This lane starts from **`{{PREV_STABLE}}` and follows the published upgrade documentation
verbatim** — it verifies the docs as much as the code, and it is the closest simulation of what
every real user does on release day. Run for every major, and for minors that touch generators,
config, or install templates.

**Prompt (run once per app: `{{UPGRADE_APP_OSS}}`, then `{{UPGRADE_APP_PRO}}`):**

```text
You are performing a release-day upgrade rehearsal for react_on_rails {{RC_TAG}}.

Setup: clone {{UPGRADE_APP}} at its current default branch into a scratch worktree; confirm it is
on the {{PREV_STABLE}} line (Gemfile.lock + package.json). If it is not, check out the last commit
that was. Do not push anything to the app repo.

Rules of the rehearsal:
- Follow the published upgrade documentation VERBATIM (docs upgrade guide for this major, the
  CHANGELOG breaking-changes section, and README install notes). Execute exactly what the docs
  say, in order.
- Every time you must do something the docs did not tell you — a missing step, a wrong command,
  an unmentioned config change, an error you had to solve by reading source — STOP, record it as
  a DOCS GAP with the exact error text and the fix you applied, then continue.
- Do not silently modernize unrelated app code. If the app needs an unrelated fix to proceed,
  record it as APP DEBT and apply the minimum.

Verification ladder (record evidence at each rung):
1. bundle install / package install succeed with the RC versions.
2. App boots in development; server-rendered and client-rendered pages respond.
3. Production build (assets:precompile or the app's build command) succeeds.
4. The app's own test suite passes (or fails only on pre-existing failures — verify by running it
   once on {{PREV_STABLE}} first).
5. Smoke the app's primary routes (per the demo-fleet.yml smoke list if this app is in the fleet):
   SSR HTML present, hydration completes without console errors, and for the Pro app: streaming
   renders, RSC routes, and (if enabled) pull-mode props work.

Output: a report with (a) verdict PASS / FAIL / PASS-WITH-GAPS, (b) the DOCS GAP list — this is
the primary deliverable; each gap becomes a docs issue before final, (c) APP DEBT list, (d) the
full diff of changes the upgrade required in the app, (e) evidence per ladder rung (commands +
key output). File each DOCS GAP as a repo issue labeled release:<X.Y.Z>-must-have if it would
strand a real upgrader, else P2/documentation.
```

**Pass criteria:** ladder rungs 1–5 pass on both apps; every DOCS GAP filed. A FAIL on any rung
that a real user would hit blocks promotion (treat as a hard gate for majors).

## Lane 2 — Debut-feature abuse pass

Adversarial behavioral testing of what is new in this release. New features have had the least
soak time, and the highest-severity review findings historically cluster where a new feature
interacts with an old mechanism. Input: Lane 0's DEBUT FEATURES list.

**Prompt (run once per debut feature; parallelize across features):**

```text
You are adversarially testing one debut feature of react_on_rails {{RC_TAG}}:

FEATURE: {{FEATURE_NAME}} — {{ONE_LINE_CONTRACT}}
DOCS: {{DOC_LINKS}}   PRS: {{PR_LINKS}}   SURFACES: {{SURFACES}}

Work in the react_on_rails monorepo at {{RC_TAG}}; use react_on_rails_pro/spec/dummy (or
react_on_rails/spec/dummy for OSS-only features) as the running app. You may add throwaway test
pages/specs in a scratch branch; do not merge anything from this session.

Method:
1. Enumerate the documented contract: inputs, outputs, defaults, error behavior, config gates.
2. Derive an abuse matrix — at minimum:
   - Invalid/boundary inputs: nil/empty/huge/wrong-type for every new option or prop.
   - Lifecycle abuse: disconnect mid-stream, navigate away mid-hydration, unmount/remount loops,
     double initialization, Turbo navigation with the feature active.
   - Concurrency: many simultaneous renders/streams using the feature; interleaving with
     caching/prerender if applicable.
   - Degraded dependencies: the feature's optional deps absent or erroring (cache store down,
     renderer restarting, RSC bundle missing) — the failure should be diagnosable, never silent.
   - Interaction sweep: run the feature against each OTHER debut feature it can co-occur with.
3. Execute the matrix. For every defect: minimal repro, severity, exact file:line hypothesis if
   you can trace it. Distinguish BROKEN (contract violated) from UNDOCUMENTED (behavior
   surprising but arguably intended) from NOISE.
4. For each confirmed BROKEN finding, write the repro as a permanent regression spec/e2e test in
   the style of react_on_rails_pro/spec/dummy/e2e-tests/rsc_fouc.spec.ts and include it in the
   report as a patch — release gates should accrete from RC findings.

Output: verdict per feature (SOLID / DEFECTS-FOUND), the defect list with repros, the patch with
permanent regression tests, and the abuse matrix with pass/fail per cell so coverage is explicit.
File BROKEN findings as issues labeled release:<X.Y.Z>-must-have (contract violations in a debut
feature ship as day-one bugs otherwise).
```

**Pass criteria:** every debut feature SOLID, or its BROKEN findings fixed/waived per the
rc-testing-plan waiver rules. Confirmed-defect repros land as permanent tests.

## Lane 3 — Stress and soak

Sustained-load behavior: memory growth, leaked handles, degradation over time. Review can flag
leak-shaped code; only a soak run proves or disproves it. Uses the repo's `stress-test` skill,
which orchestrates the destructive demo-workspace QA lane (leakage, memory, performance, hostile
inputs, fault injection) against repo-owned apps.

**Prompt:**

```text
Invoke the stress-test skill against a demo workspace running react_on_rails {{RC_TAG}}
(react_on_rails_pro/spec/dummy in production mode, or a fleet Pro demo if the skill's manifest
prefers it). This is an authorized destructive QA run on repo-owned apps only.

Focus areas for this release, in priority order:
1. Sustained streamed-RSC + incremental-render traffic (hours, not minutes): renderer worker RSS,
   Rails process RSS, open-connection counts. Watch specifically for the leak shapes flagged in
   this release's review: {{LEAK_SHAPED_ISSUES}}.
2. Client-side soak: repeated Turbo navigations across pages using the debut features; browser
   heap growth per 100 navigations; listener/observer counts.
3. Fault injection under load: kill/restart the node renderer mid-stream, drop client connections
   mid-render, exhaust the cache store — the system must degrade with diagnosable errors and
   recover without restart.
4. Hostile inputs on new protocol surfaces (oversized props, malformed control frames, absurd
   component counts) — server must reject cleanly, never hang or crash the worker pool.

Output: the skill's gated findings report plus a resource-over-time table (RSS/heap/connections
at t=0, t=30m, t=2h). Verdict: STABLE (flat resource curves, clean recovery) or findings with
severity. File leaks/hangs as issues; anything that requires a process restart to recover is
release:<X.Y.Z>-must-have.
```

**Pass criteria:** STABLE verdict, or every non-flat curve explained and its issue triaged. A
leak that accumulates under normal traffic blocks promotion.

## Lane 4 — Mechanical audits

### 4a. Changelog and migration-guide completeness

**Prompt:**

```text
Audit release-notes completeness for react_on_rails {{RC_TAG}} against the real release diff.
Inputs: Lane 0's BREAKING CHANGES and DEBUT FEATURES lists; the repo at {{RC_TAG}}. Use the
update-changelog and post-merge-audit skills where they fit; this prompt is the acceptance bar.

Check, with file/PR evidence for every claim:
1. Every Lane 0 BREAKING CHANGE appears in the CHANGELOG release section AND in the upgrade
   guide, with the user-visible consequence stated (not just the internal change).
2. Every DEBUT FEATURE has a CHANGELOG entry and documentation reachable from the docs site nav.
3. Every issue labeled release:<X.Y.Z>-must-have is closed, and its fix is in
   {{PREV_STABLE}}..{{RC_TAG}} (verify by commit, not by issue state).
4. Version-stamp coherence: gem version.rb files, every published package.json, and the CHANGELOG
   heading all agree with {{RC_TAG}}.
5. No CHANGELOG entry describes something the diff does not contain (stale/aspirational notes).

Output: a checklist table (item / status / evidence), the list of missing or wrong entries as
ready-to-apply CHANGELOG/docs patch hunks, and a verdict COMPLETE / GAPS. Gaps are cheap to fix —
open one PR carrying all patch hunks rather than issues.
```

### 4b. Published-artifact verification

Modeled on react_on_rails_rsc's `scripts/verify-release.sh` contract enforcement.

**Prompt:**

```text
Verify the publishable artifacts for react_on_rails {{RC_TAG}} before (or immediately after) npm/
gem publication. Work in the monorepo at {{RC_TAG}} with a clean install.

For each published npm package (react-on-rails, react-on-rails-pro,
react-on-rails-pro-node-renderer, create-react-on-rails-app):
1. `npm pack --dry-run` (or pack + inspect the tarball): the file list matches the package.json
   "files" globs; every entry-point/export map target exists in the tarball; no test/fixture/
   source-map junk ships; Pro packages carry the commercial license header where required
   (script/check-pro-license-headers).
2. Peer/dependency contract: react-on-rails-rsc peer range includes {{RSC_VERSION}} and excludes
   known-bad versions of that line; react/react-dom peers match the supported matrix; workspace:*
   references are rewritten to real versions in the packed manifest.
3. Install the packed tarballs (not the workspace) into a scratch app skeleton and run
   script/check-single-react-resolution.mjs — one React installation, matching versions.
4. Gems: `gem build` both gemspecs from the tag; unpack and diff the file lists against the repo
   expectations; version.rb values match the tag.
5. Cross-artifact coherence: the npm versions, gem versions, and {{RC_TAG}} agree; the rsc pin in
   packed manifests is {{RSC_VERSION}}.

Output: per-artifact table (check / result / evidence), verdict CLEAN / DEFECTS. Artifact defects
are always release blockers — a wrong tarball cannot be waived, only republished.
```

**Pass criteria:** 4a COMPLETE (or its patch PR merged into the release branch); 4b CLEAN.

## Reporting and gating

- Post each lane's report as a comment on `{{TRACKING_ISSUE}}`, using the rc-testing-plan report
  conventions (versions, evidence, tester, date). One comment per lane per RC.
- Default blocking rules, subject to the rc-testing-plan waiver process:

| Lane                     | Blocks promotion when                                               |
| ------------------------ | ------------------------------------------------------------------- |
| 1 Upgrade dry-run        | Any ladder-rung FAIL a real upgrader would hit (hard for majors)    |
| 2 Feature abuse pass     | Unfixed, unwaived BROKEN finding in a debut feature                 |
| 3 Stress/soak            | Leak under normal traffic, or non-recoverable degradation           |
| 4a Changelog audit       | Missing breaking-change entry (fix is a cheap docs PR — just do it) |
| 4b Artifact verification | Any defect (cannot be waived, only republished)                     |
| 0 Inventory              | Never (input to the others)                                         |

- Findings filed during lanes use the release must-have label for blockers
  (`release:<X.Y.Z>-must-have`) and normal P-labels otherwise, matching the repo triage scheme.

## Appendix — instantiation for 17.0.0

Parameters: `{{PREV_STABLE}}`=`v16.6.0`, `{{RC_TAG}}`=the next RC (rc.7+),
`{{RELEASE_BRANCH}}`=`release/17.0.0`, `{{RSC_VERSION}}`=`19.2.1` (gated on
[react_on_rails_rsc#148](https://github.com/shakacode/react_on_rails_rsc/issues/148) and
[#4357](https://github.com/shakacode/react_on_rails/issues/4357)).

Lane 0 head start — known debut features for Lane 2 (verify/extend via the Lane 0 prompt):
bidirectional pull-mode async props (#4048), `hydrate_on` scheduling (#4037), `cache_tags`/
`revalidate_tag` (#3964), buffered RSC static-page helpers (#4268), typed Rails actions and
response-type generation (#3942/#4259/#4260), streamed-RSC observability marks and Server-Timing
(#4222/#4251), Tailwind layout-owned packs (#4182), Pro-default create-app (#4217/#4232), FOUC
stylesheet gating (#4047), RSC 19.2 line adoption (#4357).

Lane 2/4a must-verify-fixed list (from the post–June-12 review, umbrella #4346): #4310, #4311,
#4314, #4316, #4326, #4340, #4342, #4357, and rsc#148 (via the {{RSC_VERSION}} bump).

Lane 3 `{{LEAK_SHAPED_ISSUES}}`: #4312 (executionContext leak), #4313 (source-map retention),
#4328 (`hydrate_on: visible` detached nodes), #4329 (performance-marks queue).
