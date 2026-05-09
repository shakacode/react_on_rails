# AI Security Scanner Evaluation Plan

**Revision history:** Use `git log -- internal/planning/ai-security-scanner-evaluation.md`. **Vendor snapshot:**
Re-check product names, URLs, plans, and language coverage before running the evaluation, then refresh this snapshot
annually or when a listed vendor is acquired, deprecated, or materially changes scope.

- **Last reviewed:** 2026-05-09
- **Review owner:** React on Rails maintainers
- **Next review due:** 2027-05-09

## Purpose

Evaluate whether AI-native security scanners can find actionable vulnerabilities or logic bugs in React on Rails beyond
the issues already covered by existing lint, test, dependency, and code review workflows.

This plan tracks [Issue 2018](https://github.com/shakacode/react_on_rails/issues/2018). It is an evaluation plan, not a
decision to adopt any vendor or CI integration.

> **Public planning note:** This file lives in a public repository even though the path starts with `internal/planning/`.
> Keep raw scanner findings, exploit details, private fork URLs, and intentionally vulnerable fixtures outside this repo;
> commit only sanitized summaries here.

## Scope

Evaluate the open-source gem and npm package first:

- Ruby gem code under `react_on_rails/lib`
- Ruby generators under `react_on_rails/lib/generators`
- TypeScript package code under `packages/react-on-rails/src`
- JavaScript and Ruby test fixtures that exercise SSR, ExecJS, RSC registration, and generated app setup

Evaluate React on Rails Pro separately after the OSS scan path is understood, because Pro contains separate package and
licensing boundaries.

## Existing Tooling Baseline

Compare scanner output against the current baseline before counting a finding as net-new signal:

- CodeQL configuration under `.github/codeql/codeql-config.yml`
- Dependabot security updates for npm, Bundler, and GitHub Actions under `.github/dependabot.yml`
- Existing lint, test, and code review workflows

No dedicated `bundler-audit` (CLI: `bundle-audit`), `npm audit`, or `pnpm audit` CI workflow is configured at this
snapshot. If one is added before an evaluation run, include it in this baseline before counting dependency CVEs as
net-new signal.

Record whether each verified finding is missed by the existing baseline or whether the scanner mainly improves
prioritization, explanation, or reachability analysis for a finding that existing tools already surface.

## Candidate Scanners

Start with this point-in-time vendor shortlist from the issue if the products still offer an appropriate plan at
evaluation time.

| Vendor          | Reference                  | Initial status | Before scheduling                                                                                          |
| --------------- | -------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------- |
| ZeroPath        | <https://zeropath.com/>    | Candidate      | Confirm OSS or trial plan and Ruby/TypeScript coverage.                                                    |
| Corgea          | <https://corgea.com/>      | Candidate      | Confirm OSS or trial plan and Ruby/TypeScript coverage.                                                    |
| Almanax         | <https://almanax.ai/>      | Lower priority | Evaluate only if ZeroPath, Corgea, and DryRun are unsuitable; confirm coverage beyond Web3-heavy examples. |
| DryRun Security | <https://dryrun.security/> | Candidate      | Confirm OSS or trial plan and Ruby/TypeScript coverage.                                                    |

If the named vendors are unavailable or unsuitable, look for tools in these categories:

- AI-native SAST scanners
- AI-assisted dependency reachability scanners
- AI review tools that can reason about business logic and security intent

Prefer scanners that can run on a branch without requiring broad organization-level permissions. If a free or trial plan
is not available, record that and defer paid adoption until at least one OSS scan produces a concrete finding worth
validating.

## Evaluation Dataset

Use a fixed branch and commit for the first comparison so results are reproducible:

1. Current `main`
2. A private, access-controlled fork or an established vulnerable-by-design training project that verifies the scanner
   can catch a known issue without publishing intentionally vulnerable code in the public React on Rails repository
3. A branch with a known-safe refactor to measure false positives on normal code motion

Before running scans, record the exact baselines used:

| Dataset entry       | Source                           | Branch or URL          | Commit SHA or version | Date recorded |
| ------------------- | -------------------------------- | ---------------------- | --------------------- | ------------- |
| `main`              | `react_on_rails`                 | `main`                 | `<fill full SHA>`     | `<fill date>` |
| Known-issue fixture | Private fork or training project | `<fill branch or URL>` | `<fill SHA/version>`  | `<fill date>` |
| Safe refactor       | `react_on_rails`                 | `<fill branch>`        | `<fill full SHA>`     | `<fill date>` |

> **Do not run any scanner evaluation until every cell in this table is filled in and committed.** Undocumented
> baselines produce results that cannot be reproduced or compared across evaluators.

[Issue 3265](https://github.com/shakacode/react_on_rails/issues/3265) must be closed, with every dataset table cell
filled and committed, before [Issue 2018](https://github.com/shakacode/react_on_rails/issues/2018) moves from planning to
execution.

The intentionally vulnerable fixture should be small and obvious, such as unsafe template evaluation in a test-only file.
Do not commit intentionally vulnerable fixtures, secrets, real credentials, or exploit-ready application behavior to a
public branch of this repository. Keep any private positive-control fixture non-indexable, clearly labeled test-only, and
inert: no operational code paths, real network calls, or reusable exploit payloads. Limit access to the default triage
group unless Issue 2018 assigns a narrower group for the evaluation.

## Scoring Criteria

Score each scanner against the same rubric (1 = poor, 3 = acceptable, 5 = excellent). Use weighted totals to make
security signal and operational cost comparable across evaluators:
`weighted score = score x weight`; `weighted total = sum(weighted scores) / sum(weights)`.

Example: Actionability score = 4 with weight = 1.0 produces a weighted score of 4.0. If all eight criteria score 3,
the weighted total is `(3 x 1.0 + 3 x 1.0 + 3 x 0.9 + 3 x 0.8 + 3 x 0.8 + 3 x 0.7 + 3 x 0.7 + 3 x 0.5) / 6.4 = 3.0`.

| Criterion                 | Question                                                                           | Score (1-5) | Weight (0-1) | Weighted score |
| ------------------------- | ---------------------------------------------------------------------------------- | ----------- | ------------ | -------------- |
| Actionability             | Does the finding name the concrete file, behavior, and reachable path?             |             | 1.0          |                |
| Correctness               | Can we reproduce or disprove the finding locally?                                  |             | 1.0          |                |
| False-positive rate       | How many findings are noise after local verification?                              |             | 0.9          |                |
| Ruby/Rails coverage       | Does it understand Rails generators, helpers, and server rendering paths?          |             | 0.8          |                |
| TypeScript/React coverage | Does it understand package exports, SSR utilities, and browser/runtime boundaries? |             | 0.8          |                |
| Permission model          | Can it run with minimal GitHub permissions?                                        |             | 0.7          |                |
| CI fit                    | Can results be advisory first, without failing every PR?                           |             | 0.7          |                |
| Maintenance cost          | How much config, triage time, and vendor lock-in does it add?                      |             | 0.5          |                |

Anchor examples:

- Actionability: 5 means file, reachable path, and reproduction steps; 1 means a vague pattern or generic warning.
- Correctness: 5 means locally reproduced or disproven with a clear command; 1 means the scanner cannot explain the
  finding.
- False-positive rate: 5 means most surfaced findings survive local verification; 1 means the report is mostly noise.
  If fewer than three high/critical findings are reported, record the raw count and defer scoring until a larger sample is
  available; do not extrapolate a rate from a single finding.
- Ruby/Rails coverage: 5 means it traces Rails generators, helpers, SSR, and ExecJS paths; 1 means generic Ruby syntax
  only.
- TypeScript/React coverage: 5 means it understands package exports, SSR utilities, and browser/server boundaries; 1 means
  generic JavaScript syntax only.
- Permission model: 5 means read-only repository access plus advisory comments or issues; 1 means organization-wide write,
  merge, or admin permissions.
- CI fit: 5 means advisory, opt-in, non-blocking pull request results; 1 means all pull requests are blocked by default
  with no clear override.
- Maintenance cost: 5 means near-zero configuration and triage overhead; 1 means weekly manual triage or frequent config
  churn.

## First-Pass Workflow

0. Verify the chosen scanner's current plan availability and Ruby/TypeScript coverage against the shortlist table.
   Update the table's "Initial status" and "Before scheduling" columns if anything has changed.
1. Pick the current `main` branch of `react_on_rails` and one candidate scanner from the shortlist.
2. Run the scan without enabling CI blocking.
3. Export raw findings with sensitive details into a private, access-controlled location if needed; summarize only
   sanitized, verified results in the public issue after exposure details are fixed or disproven.
   - Limit access to repository maintainers with write access, unless Issue 2018 names a narrower security triage group.
   - Omit secrets and credentials; redact reproduction snippets.
   - Delete or archive raw notes after the finding is resolved.
4. For each high or critical finding, reproduce locally or write down why it is not reachable.
   Batch-triage medium findings after the high/critical pass. Skip informational findings unless a pattern emerges.
5. Fix only verified vulnerabilities or correctness bugs.
   If a verified vulnerability affects released gem or npm package code, keep exposure details private until patched.
   Follow `SECURITY.md` for the disclosure process and approve timing with maintainers before public disclosure.
6. Summarize scanner signal in the issue before trying the next scanner.

## Adoption Bar

**Owner:** Tracked in [Issue 2018](https://github.com/shakacode/react_on_rails/issues/2018). If that issue is closed
before adoption, repository maintainers with write access own the next triage decision.
**Default triage group:** repository maintainers with write access, unless the issue assigns a narrower group.
**Default triage SLA:** first response within five business days for high or critical alerts.

Do not add a scanner to CI until all of these are true:

- Finds at least one verified issue or a clearly valuable hardening opportunity.
- Keeps the false-positive rate at or below 25% among high/critical findings on `main` after one triage pass. If the scan
  reports fewer than three high/critical findings, manually review every finding and record why the sample is too small
  for a stable rate.
- Supports advisory mode for pull requests.
- Requires only read-only repository access plus permission to post advisory PR comments or create issues; no write,
  merge, or admin permissions.
- Records the triage owner or rotation for the default SLA in this file or Issue 2018.

If no scanner clears this bar, keep the issue as a record of what was tested and revisit later.
