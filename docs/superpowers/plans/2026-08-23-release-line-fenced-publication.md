# Release-Line Fenced Publication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Make the prepared 17.1.0.rc.0 candidate pass exact-head validation and publish only through a lifetime-bound, per-write-fenced release entry point.

**Architecture:** Narrow same-candidate retry discovery to an explicitly selected tracker, make packed Pro compatibility resolve both local tarballs without registry availability, and replace the placeholder script/release with a Ruby supervisor. The supervisor owns a private liveness pipe, an independent parent-death pipe, and a release process group; a focused lease guard validates that contract and performs authoritative agent-coord checks immediately before every outward write, while the death watch kills the group if the supervisor disappears.

**Tech Stack:** Ruby, Rake, RSpec, Bash, Node.js ESM, pnpm, node:test, GitHub CLI, agent-coord HTTP backend.

**Spec:** docs/superpowers/specs/2026-08-23-release-line-fenced-publication-design.md

## Global Constraints

- Preserve 17.1.0.rc.0; never reset or force-push release/17.1.0.
- Tests never call real registries or perform GitHub/Git writes.
- Direct live bundle exec rake release fails closed; dry runs stay lease-free.
- The wrapper requires an existing claim and never takes over or releases it.
- Every retry of an outward write receives a fresh authoritative fence.
- Preserve/add the canonical Pro license header for changed/new Pro files.

---

### Task 1: Scope same-candidate retry discovery to the selected tracker

**Files:**

- Modify: rakelib/release.rake
- Test: react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb

**Interfaces:**

- Consumes: tracker: on resolve_accelerated_rc_options_for_release!.
- Produces: tracker-aware candidate history discovery; nil retains repository discovery.

- [ ] **Step 1: Write failing selected-tracker specs**

Pass tracker: "4842" for an unflagged same-candidate retry and expect candidate discovery with tracker: 4842. Assert an empty selected tracker preserves ordinary retry, a selected tracker containing the existing authorization resumes accelerated mode, and a record bound to another tracker aborts.

- [ ] **Step 2: Run and verify RED**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_rake_helpers_spec.rb   --example "resolve_accelerated_rc_options_for_release")
```

Expected: failure because candidate discovery does not accept tracker:.

- [ ] **Step 3: Implement tracker-aware discovery**

Change fetch_repository_issue_comments_for_accelerated_rc_retry! to accept tracker: nil and delegate to fetch_bounded_accelerated_rc_marker_comments! with that tracker. Normalize an explicit tracker to a positive integer, pass it through same-candidate authorization/history helpers, and validate trusted records against the selected issue. Preserve repository-wide discovery when tracker is nil.

- [ ] **Step 4: Run focused and pagination specs**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_rake_helpers_spec.rb   --example "resolve_accelerated_rc_options_for_release"   --example "bounded selected and repository discovery"   --example "page bound")
```

Expected: GREEN; selected discovery calls issues/4842/comments.

- [ ] **Step 5: Commit**

```bash
git add rakelib/release.rake react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb
git commit -m "Fix bounded RC retry discovery"
```

---

### Task 2: Make packed Pro compatibility registry-independent

**Files:**

- Create: packages/react-on-rails-pro/scripts/packed-react-compatibility-manifest.mjs
- Create: packages/react-on-rails-pro/scripts/packed-react-compatibility-manifest.test.mjs
- Modify: packages/react-on-rails-pro/scripts/packed-react-compatibility-smoke.mjs
- Modify: packages/react-on-rails-pro/package.json

**Interfaces:**

- Produces: buildPackedCompatibilityManifest with packageManager, reactVersion, coreArtifact, and proArtifact inputs.

- [ ] **Step 1: Write the failing manifest test**

Require both direct file tarball dependencies and pnpm.overrides["react-on-rails"] equal to the same local OSS tarball. Also assert React, React DOM, webpack, package-manager, and private-package fields. Include the proprietary header.

- [ ] **Step 2: Run and verify RED**

```bash
node --test packages/react-on-rails-pro/scripts/packed-react-compatibility-manifest.test.mjs
```

Expected: module-not-found.

- [ ] **Step 3: Extract the manifest builder**

Return the existing consumer manifest plus a pnpm override forcing every react-on-rails resolution to file:coreArtifact. Use it from the smoke and run the new unit test before the existing cases test and smoke.

- [ ] **Step 4: Verify GREEN**

```bash
node --test packages/react-on-rails-pro/scripts/packed-react-compatibility-manifest.test.mjs
pnpm --filter react-on-rails-pro run test:packed-react-compatibility
ruby script/check-pro-license-headers --check
```

- [ ] **Step 5: Commit**

```bash
git add packages/react-on-rails-pro/scripts/packed-react-compatibility-*   packages/react-on-rails-pro/package.json
git commit -m "Test packed Pro packages without registry publication"
```

---

### Task 3: Build the release lease guard and supervisor

**Files:**

- Create: rakelib/release_lease_guard.rb
- Replace: script/release
- Create: react_on_rails/spec/react_on_rails/release_lease_guard_spec.rb
- Create: script/release-test.bash

**Interfaces:**

- Produces: ReleaseLeaseGuard.activate!, ReleaseLeaseGuard.fence!, and ReleaseLeaseGuard.active?.
- Wrapper usage: script/release 17.1.0.rc.0.
- Private contract: inherited read FD, parent PID, PGID, repo, target, branch, agent ID, instance ID, and machine ID. Never a token.

- [ ] **Step 1: Write failing guard specs**

With injected status reader, clock, process adapter, and liveness IO, assert direct live activation fails without the wrapper, a matching claim/heartbeat passes, and each of these aborts: inactive/expired/unknown claim, wrong repo/target/branch/agent/instance/machine, dead heartbeat, closed parent channel, and wrong process group. Dry-run performs no coordination read.

- [ ] **Step 2: Run and verify RED**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_lease_guard_spec.rb)
```

Expected: missing guard file.

- [ ] **Step 3: Implement the guard**

Parse an immutable private contract, verify inherited FD and parent/PGID relationship, perform targeted agent-coord status JSON reads, and require one exact active claim plus one live matching heartbeat. Use nonblocking liveness reads so open/idle differs from EOF. Never log credentials.

- [ ] **Step 4: Write failing wrapper integration tests**

Use temporary fake agent-coord and bundle executables. Assert dry-run needs no identity; live mode refuses missing identity; matching state starts one process group; heartbeat retains identity; lease failure closes liveness and terminates the group; signals report PGID; no claim is released; fake secrets never appear.

- [ ] **Step 5: Replace script/release**

Implement Ruby OptionParser. Validate explicit version and matching release/X.Y.Z branch, open a private pipe, spawn bundle exec rake release[VERSION] in a dedicated process group, heartbeat every 60 seconds, poll child, and terminate the group on lease/signal failure. --dry-run runs release[VERSION,true] without coordination.

- [ ] **Step 6: Verify GREEN**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_lease_guard_spec.rb)
bash script/release-test.bash
```

- [ ] **Step 7: Commit**

```bash
git add rakelib/release_lease_guard.rb script/release script/release-test.bash   react_on_rails/spec/react_on_rails/release_lease_guard_spec.rb
git commit -m "Add lifetime-bound release lease supervisor"
```

---

### Task 4: Fence every outward write

**Files:**

- Modify: rakelib/release.rake
- Test: react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb

**Interfaces:**

- Activates the guard after exact version/branch resolution.
- Calls release_write_fence!(operation) immediately before each mutation.

- [ ] **Step 1: Write failing boundary-order specs**

Use ordered expectations for the version push, ShakaPerf dispatch/evidence comments, tag push, four named npm attempts, two named gem attempts, accelerated tracker writes, and GitHub release create/edit. Prove two registry attempts cause two fences. Prove direct live invocation aborts before authentication/mutation while dry-run remains guard-free.

- [ ] **Step 2: Run and verify RED**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_rake_helpers_spec.rb   --example "outward write" --example "direct live" --example "publish retry")
```

- [ ] **Step 3: Integrate the guard**

Require the guard and activate it before live authentication. Add a release_write_fence! delegator. Fence the version push, each ShakaPerf workflow dispatch and durable comment, tag push, every npm attempt inside its retry loop, every gem attempt inside its retry loop, accelerated tracker writes, and GitHub release create/edit. Do not fence local builds or visibility probes.

- [ ] **Step 4: Verify GREEN**

```bash
(cd react_on_rails && bundle exec rspec   spec/react_on_rails/release_lease_guard_spec.rb   spec/react_on_rails/release_rake_helpers_spec.rb)
bash script/release-test.bash
```

- [ ] **Step 5: Commit**

```bash
git add rakelib/release.rake react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb
git commit -m "Fence every release publication write"
```

---

### Task 5: Update runbook and test routing

**Files:**

- Modify: internal/contributor-info/release-train-runbook.md
- Modify: internal/contributor-info/releasing.md
- Modify: script/ci-changes-detector-test.bash
- Modify: rakelib/release.rake

- [ ] **Step 1: Add failing assertions**

Require release help to name script/release VERSION, preserve direct-live refusal, and route changes to the wrapper, wrapper test, and lease guard through release-tooling tests.

- [ ] **Step 2: Run and verify RED**

```bash
(cd react_on_rails && bundle exec rspec spec/react_on_rails/release_rake_helpers_spec.rb   --example "documents")
bash script/ci-changes-detector-test.bash
```

- [ ] **Step 3: Document the fenced path**

Replace applicable BLOCKED instructions with the wrapper path while preserving the ban on bare live Rake. Document identity variables, existing claim, liveness/heartbeat, no automatic takeover/release, dry run, and partial-publication rules.

- [ ] **Step 4: Verify and commit**

```bash
pnpm exec prettier --check internal/contributor-info/release-train-runbook.md   internal/contributor-info/releasing.md
bash script/ci-changes-detector-test.bash
git diff --check
git add internal/contributor-info/release-train-runbook.md internal/contributor-info/releasing.md   script/ci-changes-detector-test.bash rakelib/release.rake
git commit -m "Document the fenced release entry point"
```

---

### Task 6: Validate and publish the PR

**Files:** all changed files.

- [ ] **Step 1: Run focused verification**

```bash
(cd react_on_rails && bundle exec rspec   spec/react_on_rails/release_lease_guard_spec.rb   spec/react_on_rails/release_rake_helpers_spec.rb)
pnpm --filter react-on-rails-pro run test:packed-react-compatibility
bash script/release-test.bash
bash script/ci-changes-detector-test.bash
ruby script/check-pro-license-headers --check
```

- [ ] **Step 2: Run mandatory validation**

```bash
(cd react_on_rails && BUNDLE_GEMFILE=../Gemfile bundle exec rubocop)
(cd react_on_rails_pro && BUNDLE_GEMFILE=../Gemfile bundle exec rubocop --ignore-parent-exclusion)
pnpm run lint
pnpm start format.listDifferent
.agents/bin/validate
git diff --check
```

- [ ] **Step 3: Self-review**

```bash
git diff --stat origin/release/17.1.0...HEAD
git diff --check origin/release/17.1.0...HEAD
git diff origin/release/17.1.0...HEAD
```

Confirm version remains 17.1.0.rc.0, package contents are unchanged beyond test tooling, Pro headers are intact, and every mutation has an adjacent fence.

- [ ] **Step 4: Follow PR processing, push, and open**

Follow .agents/workflows/pr-processing.md, then push jg-codex/release-17-1-rc-unblock and create a PR targeting release/17.1.0 titled "Release: fence and unblock 17.1.0.rc.0 publication". The body records interrupted state, three root causes, no-artifact proof, tracker #4842, and exact-head validation plan. Request hosted CI only after local validation and ensure packed Pro jobs execute.

---

### Task 7: Merge under lease and publish 17.1.0.rc.0

**Files:** external release state only.

- [ ] **Step 1: Acquire a fresh identity and merge**

Prove earlier Sasha/Justin release processes are terminated, acquire release-line:17.1.0, start heartbeat, and merge only the reviewed exact PR head after a live owner preflight.

- [ ] **Step 2: Run exact-head full CI and ShakaPerf**

Dispatch all nine workflows at the merged SHA, inspect job execution, require required jobs to pass, then dispatch/verify exact-head ShakaPerf with RELEASE_TRACKER=4842.

- [ ] **Step 3: Record authority and preview**

Record explicit tag/publication authority on #4842, then run:

```bash
script/release --dry-run 17.1.0.rc.0
```

- [ ] **Step 4: Run the live fenced release**

```bash
RELEASE_TRACKER=4842 script/release 17.1.0.rc.0
```

Enter fresh npm and RubyGems OTPs only at prompts. Stop on unknown lease, SHA, CI, ShakaPerf, registry, or artifact state.

- [ ] **Step 5: Independently verify all artifacts**

Verify four npm packages at 17.1.0-rc.0, both gems at 17.1.0.rc.0 with --prerelease, tag v17.1.0.rc.0, and the GitHub prerelease. Record exact evidence on #4842, keep the train lease until normal handoff/closeout, and forward-port the release-safety changes to main.
