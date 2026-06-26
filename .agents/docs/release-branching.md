# Release Branching

Shared workflows treat release branching as consumer-repo policy. The target
repo's `AGENTS.md` must define how to identify release trackers, target
branches, and merge gates.

The portable default vocabulary is:

- **beta**: ordinary development work, usually targeting the base branch.
- **rc**: stabilization work targeting a release branch.
- **final**: promotion or final-release work requiring explicit human sign-off.

Agents must select the gate from the target branch's phase, then apply the
consumer repo's release policy from `AGENTS.md`.

If the repo uses release branches, `AGENTS.md` should specify:

- branch naming, such as `release/X.Y.Z`;
- whether fixes on release branches must be forward-ported to the base branch;
- whether final promotion can be automated;
- which checks, audits, or human approvals are required in each phase.

If release phase cannot be verified, report `UNKNOWN` and avoid auto-merge.
