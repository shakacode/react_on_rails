# Release-Line Fenced Publication Design

## Context

The first `17.1.0.rc.0` attempt pushed the generated version commit
`8e4358cfdc811d57d76fd70dbb5ff8c90913dc57` and then stopped before creating a
tag or publishing any package. Three independent defects prevent a safe retry:

1. A normal same-candidate retry scans all historical repository issue comments
   looking for a prior accelerated-RC authorization. The bounded scan fails once
   a repository has more historical comments than its fixed page limit.
2. The packed Pro compatibility smoke installs locally packed OSS and Pro
   tarballs, but pnpm still resolves the Pro tarball's exact `react-on-rails`
   dependency from npm. Exact-head CI therefore cannot pass until the version
   being tested has already been published.
3. The live release task performs a branch push, tag push, four npm publishes,
   two RubyGems pushes, tracker writes, workflow dispatch, and GitHub release
   mutation as one compound writer. The task has no release-line ownership
   check at each outward-write boundary and no lifetime binding between a
   supervisor and the helper process group.

No `17.1.0.rc.0` tag, npm package, RubyGem, or GitHub release exists. The remote
release branch currently points at the recoverable version commit above.

## Goals

- Preserve the prepared `17.1.0.rc.0` version and changelog instead of resetting
  or force-pushing the release branch.
- Bound authoritative repository-wide same-candidate discovery from the
  candidate commit timestamp without trusting eventually indexed issue search.
- Make exact-head packed-package CI independent of whether the candidate has
  already been published.
- Provide one repository-owned live-release entry point that maintains a live
  canonical `agent-coord` lease, binds the release helper process group to its
  supervisor, and fails closed immediately before every outward write.
- Keep dry runs usable without a coordination lease.
- Preserve idempotent recovery checks for artifacts that may become visible
  after an uncertain registry response.

## Non-goals

- Changing package contents, public APIs, or the six-package publication order.
- Weakening CI, ShakaPerf, OTP, registry-conflict, tracker, or exact-SHA gates.
- Allowing a maintainer approval or environment flag to bypass a missing,
  expired, mismatched, or unknown release-line lease.
- Automating claim takeover. A new process must still prove prior process-group
  termination before acquiring a released or expired claim.

## Design

### Candidate-bounded authoritative same-candidate discovery

`resolve_accelerated_rc_options_for_release!` passes an explicitly supplied
`RELEASE_TRACKER` as the expected canonical tracker. Discovery obtains the
candidate commit timestamp, then reads the authoritative repository issue-comment
endpoint from that time forward. It retains bounded pagination, schema,
authorship, append-only, and conflicting-record validation across every tracker.
Candidate timestamps in the future, records predating the candidate, incomplete
bounded enumeration, and any tracker mismatch fail closed. GitHub issue search
may lag new comments and is not used to prove absence.

### Registry-independent packed compatibility

The generated compatibility consumer will continue installing both locally
packed tarballs. Its pnpm configuration will additionally override every
`react-on-rails` resolution to the local OSS tarball. This makes the dependency
inside the packed Pro manifest resolve to the same artifact as the consumer's
direct dependency.

The existing runtime assertion that the consumer and Pro package resolve the
same OSS package instance remains the behavioral proof. A focused test will
also inspect the generated consumer manifest so removing the transitive override
fails without requiring registry access.

### Live release entry point

A repository-owned wrapper will become the only supported live entry point.
Bare `bundle exec rake release` remains available for dry-run mode but will
refuse live execution unless the wrapper establishes a private guard contract.
The contract will not contain the machine token; it will contain only the
canonical repository, target, branch, process-unique agent ID, instance ID,
machine ID, supervisor PID/process-group ID, and a private parent-liveness
channel.

The wrapper will:

1. Select the prepared release version from the first stamped section directly
   below `Unreleased` and derive the exact `release-line:X.Y.Z` target.
2. By default, create a process-unique identity and atomically acquire that
   release-line claim. When both coordinator identity variables are supplied,
   preserve the advanced automation path by verifying its pre-acquired claim
   instead of taking ownership of claim cleanup.
3. Start a dedicated process group containing the release helper and every
   command it spawns.
4. Maintain the heartbeat at an interval below the runbook's five-minute
   maximum and renew a wrapper-managed claim before it can expire.
5. Maintain a private liveness channel into the helper plus an independent
   parent-death channel watched by a process in the release group. Loss of the
   supervisor closes both channels; the death watch immediately kills the full
   group, including an outward command already in progress.
6. On lease refresh or managed-claim renewal failure, terminate the process
   group and exit nonzero.
7. On normal completion or interruption, stop heartbeat activity, terminate any
   remaining children, and report the exact process group that must be proven
   dead before handoff. Release an exact wrapper-managed claim only after that
   proof; leave a pre-acquired automation claim under its external owner's
   lifecycle.

On Linux, the supervisor also uses subreaper support to adopt and reap orphaned
descendants. macOS has no subreaper equivalent, so launchd reaps orphans there;
the dedicated process-group kill and `kill(0, -pgid)` absence check are the
authoritative handoff proof on both platforms.

The helper will validate that the wrapper contract belongs to its own parent and
process group. A forged environment variable without the live private channel
will fail closed.

### Per-write fences

The release helper will call one guard method immediately before each outward
write. The guard will perform a fresh authoritative targeted `agent-coord`
status read and require all of the following:

- claim status is active and unexpired;
- repository and target equal `shakacode/react_on_rails` and
  `release-line:X.Y.Z`;
- agent ID, instance ID, machine ID, and branch match the wrapper contract;
- heartbeat is live and belongs to the same identity;
- supervisor liveness channel and process-group identity are intact.

Fences cover, at minimum:

- pushing a generated version commit;
- dispatching or recording ShakaPerf release evidence;
- pushing the annotated release tag;
- each of the four npm package publications;
- each of the two RubyGem publications;
- accelerated-RC tracker mutations, when applicable;
- GitHub release creation or update.

Read-only checks, local builds, package packing, OTP collection, and dry-run
rendering do not require a write fence. Artifact verification immediately after
an uncertain publish remains read-only, but a retry of the publish requires a
new fence.

### Release retry behavior

For the current RC, the wrapper will select the prepared changelog version and
run with `RELEASE_TRACKER=4842`. The release task will detect that the version files are
already set, avoid creating another bump commit, and run all gates at the new
exact candidate SHA after this change merges. Publication proceeds only after:

- every required exact-head hosted job actually executed and passed;
- an exact-head ShakaPerf run was dispatched or selected and verified;
- tracker #4842 records explicit tag/publication authority;
- the canonical release-line claim is active under the live wrapper identity.

## Failure handling

- Any unknown coordination response is a hard stop.
- A supervisor, liveness-channel, heartbeat, identity, branch, or process-group
  mismatch is a hard stop before the next write.
- Once a tag or immutable package exists, the wrapper relies on existing
  idempotent artifact probes and the runbook's partial-publication rules. It
  never deletes tags, overwrites package versions, or force-pushes the branch.
- If only a subset of packages becomes visible, stop and record exact evidence;
  resume only through the same fenced identity or a separately approved,
  fully-fenced reconciliation after proving the original process group dead.

## Verification

Automated tests will cover:

- tracker-scoped retry discovery and fail-closed mismatch cases;
- preservation of persisted accelerated authorization on the selected tracker;
- generated packed-consumer override and single-instance resolution;
- rejection of direct live rake invocation;
- wrapper-contract validation and parent-liveness loss;
- lease, heartbeat, identity, branch, and process-group mismatch failures;
- one fresh fence before each outward write and before each retry;
- dry-run behavior without coordination credentials;
- simulated partial publication and idempotent retry behavior using local
  fakes—never real registries.

Local validation will include the focused Ruby release-helper specs, the packed
Pro compatibility test, Pro license-header validation, RuboCop, JavaScript lint,
and formatting checks. Hosted validation must run against the exact merged
release-branch SHA before any tag or registry write.

## Rollout

1. Merge the implementation PR into `release/17.1.0` under the canonical lease.
2. Run exact-head full hosted CI and exact-head ShakaPerf.
3. Record explicit publication authority on tracker #4842.
4. Acquire a fresh process-unique release-line identity and invoke the wrapper.
5. Verify all six artifacts, the tag, and the GitHub prerelease independently.
6. Forward-port the release-safety changes to `main` if the release branch PR is
   not already based on code shared with `main`.
