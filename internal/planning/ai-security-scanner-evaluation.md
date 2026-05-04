# AI Security Scanner Evaluation Plan

## Purpose

Evaluate whether AI-native security scanners can find actionable vulnerabilities or logic bugs in React on Rails beyond
the issues already covered by existing lint, test, dependency, and code review workflows.

This plan tracks [Issue 2018](https://github.com/shakacode/react_on_rails/issues/2018). It is an evaluation plan, not a
decision to adopt any vendor or CI integration.

## Scope

Evaluate the open-source gem and npm package first:

- Ruby gem code under `react_on_rails/lib`
- Ruby generators under `react_on_rails/lib/generators`
- TypeScript package code under `packages/react-on-rails/src`
- JavaScript and Ruby test fixtures that exercise SSR, ExecJS, RSC registration, and generated app setup

Evaluate React on Rails Pro separately after the OSS scan path is understood, because Pro contains separate package and
licensing boundaries.

## Candidate Scanner Categories

Use this point-in-time candidate list from the issue if the products still offer an appropriate plan at evaluation time:

- ZeroPath
- Corgea
- Almanax
- DryRun
- AI-native SAST scanners
- AI-assisted dependency reachability scanners
- AI review tools that can reason about business logic and security intent

Prefer scanners that can run on a branch without requiring broad organization-level permissions. If a free or trial plan
is not available, record that and defer paid adoption until at least one OSS scan produces a concrete finding worth
validating.

## Evaluation Dataset

Use a fixed branch and commit for the first comparison so results are reproducible:

1. Current `main`
2. A private fork, private Gist, or existing vulnerable-by-design project that verifies the scanner can catch a known
   issue without publishing intentionally vulnerable code in the public React on Rails repository
3. A branch with a known-safe refactor to measure false positives on normal code motion

The intentionally vulnerable fixture should be small and obvious, such as unsafe template evaluation in a test-only file.
Do not commit intentionally vulnerable fixtures, secrets, real credentials, or exploit-ready application behavior to a
public branch of this repository.

## Scoring Criteria

Score each scanner against the same rubric:

| Criterion                 | Question                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------- |
| Actionability             | Does the finding name the concrete file, behavior, and reachable path?             |
| Correctness               | Can we reproduce or disprove the finding locally?                                  |
| False-positive rate       | How many findings are noise after local verification?                              |
| Ruby/Rails coverage       | Does it understand Rails generators, helpers, and server rendering paths?          |
| TypeScript/React coverage | Does it understand package exports, SSR utilities, and browser/runtime boundaries? |
| Permission model          | Can it run with minimal GitHub permissions?                                        |
| CI fit                    | Can results be advisory first, without failing every PR?                           |
| Maintenance cost          | How much config, triage time, and vendor lock-in does it add?                      |

## First-Pass Workflow

1. Pick one OSS branch and one scanner.
2. Run the scan without enabling CI blocking.
3. Export raw findings with sensitive details into a private Notion or Google Doc if needed; summarize only sanitized,
   verified results in the public issue after exposure details are fixed or disproven.
4. For each high or critical finding, reproduce locally or write down why it is not reachable.
5. Fix only verified vulnerabilities or correctness bugs.
6. Summarize scanner signal in the issue before trying the next scanner.

## Adoption Bar

Do not add a scanner to CI until all of these are true:

- It found at least one verified issue or a clearly valuable hardening opportunity.
- It produced a manageable number of false positives on `main`.
- It supports advisory mode for pull requests.
- Its required permissions are acceptable for the repository.
- The team agrees who owns triage of new alerts.

If no scanner clears this bar, keep the issue as a record of what was tested and revisit later.
