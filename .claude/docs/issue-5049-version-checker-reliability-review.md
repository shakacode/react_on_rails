# Issue #5049 — VersionChecker reliability review: findings and decisions

> **Implementation status (2026-09-11):** the #5049 PR scope below is IMPLEMENTED on this branch
> via TDD (`lib/react_on_rails/version_checker/lockfile_resolution.rb` + reworked
> `NodePackageVersion`; legacy yarn/npm-only parsers and their injected-path constructor args
> removed; fixture dirs under `spec/react_on_rails/fixtures/lockfiles/` hold real generated
> lockfiles per format version). Diagnostics implement the taxonomy with class-prefixed messages;
> the unreadable flavor carries the parser error's first line as detail. Follow-up issues A and B
> below are NOT yet filed.

Issue: https://github.com/shakacode/react_on_rails/issues/5049
Branch: `5049-core-versionchecker-only-resolves-versions-from` (from `origin/main` @ `e560acd`)
Date: 2026-09-11

While planning #5049 (extend lockfile version resolution to pnpm, bun, and Yarn v2+/Berry),
four adjacent reliability problems in the existing resolution mechanism were identified and
each was adversarially reviewed by a dedicated subagent against the actual code and real
package-manager behavior. This document records the findings and the fix/document decisions.

Key code under review:

- `react_on_rails/lib/react_on_rails/version_checker.rb`
  - `NodePackageVersion.yarn_lock_path` / `package_lock_path` (~459-471)
  - `resolve_version` (~581-600)
  - `version_from_yarn_lock` (~616-641)
- `react_on_rails/lib/react_on_rails/utils.rb` — `detect_package_manager*` (~277-345)
- `react_on_rails/lib/react_on_rails/rsc_rspack_support.rb` — installed-version machinery (~40-198)
- `react_on_rails/lib/react_on_rails/engine.rb:28-36` — check runs in `config.after_initialize`, raises → boot abort

---

## Problem 1 — Lockfile location assumes same dir as package.json (no upward traversal; breaks workspaces/monorepos)

**Claim.** `yarn_lock_path`/`package_lock_path` build `Rails.root + node_modules_location + <lockname>`.
All four package managers hoist the lockfile to the workspace root in monorepos, so for a Rails
app (or its `client/` dir) that is a workspace member, the checker finds no lockfile, silently
falls back to the raw `package.json` spec (e.g. `^17.0.0`), and `validate_exact_version!` aborts
boot — even for Yarn v1/npm users.

**Verdict: CONFIRMED (mechanics); severity lower than first framed.**

Evidence and nuances:

- Causal chain verified: `version_checker.rb:459-471` (comment literally says "Lockfiles are in
  the same directory as package.json"), silent fallback at `resolve_version` (581-600), raise via
  `range_operator?` catching `^`, boot abort via `engine.rb:28-36`.
- The `workspace:`/local-path exemption does **not** cover the affected audience: it only fires
  when the react-on-rails spec itself is `workspace:`/path/URL (how this repo's own dummy apps
  dodge it — why CI never sees the gap). A workspace member consuming react-on-rails from the
  registry has `^x.y.z` and gets no exemption.
- `node_modules_location = Rails.root.join("..")` (documented in
  `docs/oss/configuration/README.md:859-868`) is only a partial workaround: it moves the
  package.json expectation too, so it only works when the workspace ROOT package.json declares
  react-on-rails; otherwise it triggers "No React on Rails npm package is installed".
- Corroborating inconsistency: `Utils.detect_package_manager_from_lock_files` checks only
  `Rails.root` and doesn't walk up either, so the suggested install command also degrades to the
  yarn default in hoisted monorepos.
- Severity mitigations: zero field reports found (`gh search`); the failure is loud with the
  exact correct fix command in the message (exact-pinning fully resolves it — the universal
  requirement for all users before #1898); `REACT_ON_RAILS_SKIP_VALIDATION=true` exists.
- Likelihood: LOW-MEDIUM today, **rising after #5049** — pnpm users skew monorepo, and pnpm
  workspaces put `pnpm-lock.yaml` ONLY at the workspace root, so #5049's same-dir pnpm parsing
  still misses the workspace segment of its own target audience.
- Fix wrinkle: finding the hoisted file isn't sufficient for pnpm — workspace `pnpm-lock.yaml`
  keys versions under `importers.<relpath-to-member>`, so the pnpm parser must select the
  importer by the package.json dir's path relative to the lockfile dir (single-project lockfiles
  use `importers."."`).

**Decision: fix in a separate follow-up PR (difficulty M, ~0.5–1 day), plus a troubleshooting
docs entry now.** The walk-up needs its own review (stop conditions: first hit; hard-stop at
workspace-root markers — `pnpm-workspace.yaml`, package.json with `workspaces` —, `.git`, or
filesystem root) and shouldn't ride a P1 already touching four parsers.

**Two structural asks folded into the #5049 PR so the follow-up stays small:**

1. Structure lockfile discovery as a single candidates helper (one place to add the walk-up later).
2. Make the pnpm parser importer-keyed rather than hard-coding `"."` — needed for correctness
   anyway; ~90% of the workspace-lockfile parsing work.

---

## Problem 2 — Fixed lockfile precedence (yarn.lock → package-lock.json), ignoring the manager actually in use

**Claim.** `resolve_version` tries lockfiles in a fixed order regardless of the actual package
manager. A stale `yarn.lock` left behind after migrating to npm wins over the fresh
`package-lock.json` → false boot failure (or, if the stale version happens to equal the gem
version, a false pass / silent skew). Detection is also inconsistent with `utils.rb`.

**Verdict: CONFIRMED — plus one aggravating detail: the inconsistency is three-way.**

Evidence:

- Fixed order confirmed at `resolve_version` (`version_checker.rb:581-600`); no consultation of
  `Utils.detect_package_manager` or the `packageManager` field. The order is even pinned by a
  spec: `version_checker_spec.rb:1189-1200` ("prefers yarn.lock over package-lock.json").
- Three-way detection inconsistency:
  1. version checker resolves package.json AND lockfiles at `Rails.root + node_modules_location`;
  2. `detect_package_manager_from_package_json` (utils.rb:322-334) reads package.json at
     `Rails.root + node_modules_location` — consistent;
  3. `detect_package_manager_from_lock_files` (utils.rb:337-344) checks **bare `Rails.root`
     only** — wrong directory for apps with `node_modules_location: "client"` — with its own
     fixed yarn→pnpm→bun→npm priority and a `:yarn` default. So "just reuse
     Utils.detect_package_manager" would import the Rails.root bug into the version checker.
- `utils.rb:331` discards the version half of `packageManager` (`split("@").first`), throwing
  away "yarn@3.6.0 ⇒ Berry" information — though for choosing the yarn.lock PARSER,
  content-sniffing (Berry lockfiles contain `__metadata:` and unquoted `version: x`) is more
  reliable than the field anyway. Utils also checks `bun.lockb` (binary, unparseable).
- Likelihood: low-to-moderate (most migrations delete the old lockfile; harmless when both are
  in sync). But #5049 makes it strictly worse: 5 candidate formats, and migration TO pnpm/bun is
  exactly the population #5049 serves. Severity moderate: false mismatch = hard boot failure
  with a misleading version in the error; false pass = silent skew (worse, rarer).

**Decision: FIX INSIDE THE #5049 PR (difficulty S–M, ~0.5–1 day incl. tests).** The ordering
logic lives in exactly the function #5049 must rewrite, and the pinned-order spec is in the same
file the PR must touch — deferring means churning the same method/fixtures/specs twice.

Fix design (FINAL — maintainer decision, superseding two earlier drafts):

Two earlier drafts were rejected. (1) A plain ordered-fallback chain ("detected manager first,
others as fallback") reintroduces the stale hazard: whenever the primary lockfile can't answer,
any secondary hit is by definition suspect. (2) An agreement-based scheme (parse all lockfiles,
compare, warn on disagreement) still silently picks a winner in conflict cases. The maintainer's
decision: **trust only a confidently detected package manager and NEVER read another manager's
lockfile; when detection is not confident, emit a clear diagnostic instead of guessing.**

Confidence model (signals: `packageManager` field in package.json at `node_modules_location`,
and lockfile presence in the same dir; per-manager lockfile sets: yarn.lock;
package-lock.json/npm-shrinkwrap.json; pnpm-lock.yaml; bun.lock/bun.lockb):

- CONFIDENT:
  - `packageManager` field present AND that manager's lockfile exists → that manager. Extra
    lockfiles from other managers are ignored as presumed stale (`Rails.logger.warn` names
    them and recommends deletion — a diagnostic aid, never a data source).
  - No field, exactly one manager's lockfile present → that manager.
- NOT CONFIDENT (ambiguous):
  - No field, multiple managers' lockfiles present.
  - Field present but its own lockfile is ABSENT while a different manager's lockfile exists
    (declared-vs-disk conflict; covers the stale-`packageManager`-field scenario).

Resolution:

- Confident → parse ONLY the detected manager's lockfile (shape-dispatched per the format
  matrix section). If it is unparseable or lacks the package entry → fall through to the
  package.json spec (NEVER to another manager's lockfile); error text suggests the DETECTED
  manager's install command. `bun.lockb`-only projects land here: confident (bun), binary
  unreadable → package.json spec + text-lockfile migration hint.
- Ambiguous → consult NO lockfile. Check the package.json spec under the strict exact-version
  rule. If the spec is an exact matching pin, the check passes (the app is provably
  consistent) — but still warn about the ambiguity. If the spec is a range or mismatched, the
  boot error fires and its message MUST name the ambiguity and the three fixes:
  1. delete the stale lockfile(s) (list the ones found),
  2. or declare the real manager in package.json's `packageManager` field,
  3. or pin the exact version (install command per best-guess manager, defaulting as
     Utils does today).
     Never resolve a version from a guessed lockfile.

Implementation notes:

1. Detection helper parameterized by base directory (or minimal in-checker detection), fixing
   the `Rails.root` vs `node_modules_location` split as a side effect. No circular-dependency
   risk (version_checker already calls Utils; Utils never references VersionChecker).
2. Choose yarn.lock parser by content-sniffing (`__metadata:` → Berry), not the
   `packageManager` version field — this is intra-manager format selection, not cross-manager
   fallback, so it does not violate the trust rule.
3. Tests: `utils_spec.rb:608-756` already covers `detect_package_manager` with ready mocking
   patterns; rewrite the pinned-order spec at `version_checker_spec.rb:1189-1200` + fixture
   combos for: single lockfile per manager (confident); field + own lockfile + stale extra
   (confident, extra ignored + warning); no field + two lockfiles (ambiguous: exact pin passes
   with warning; range spec raises with ambiguity diagnostic); field without its lockfile but
   another manager's present (ambiguous, same diagnostic); confident manager whose lockfile
   lacks the entry (package.json fallback, detected manager's install command in message).

Still deferred: the broader Utils `Rails.root` unification. Behavior change to release-note:
projects with multiple conflicting lockfiles and a range spec previously booted using the
yarn.lock version; they now get the ambiguity diagnostic.

---

## Problem 3 — The lockfile records intent, not what's installed (node_modules drift)

**Claim.** Ground truth for "installed" is `node_modules/react-on-rails/package.json` →
`version`. Drift scenarios: lockfile changed via git pull but install not re-run; `npm install
--no-save`; installs run with a different manager than the parsed lockfile; deploy images that
prune/regenerate differently. Suggested hierarchy: node_modules (if present) → lockfile →
package.json spec, reusing the RSC installed-version machinery.

**Verdict: PARTIALLY CONFIRMED — real fidelity gap; severity overstated; one critical
implementation correction.**

Evidence and nuances:

- Drift scenario (a) is real and uncaught: after `git pull` without install, the check passes
  against the pulled lockfile while the dev server compiles from stale node*modules → confusing
  protocol-mismatch SSR/hydration errors with no version hint. No runtime gem-vs-npm assertion
  exists in the JS package, and doctor's gem/npm match check reads the \_declared* spec
  (`system_checker.rb:225-248`) — same blind spot.
- **Critical finding:** the RSC `NODE_PACKAGE_RESOLUTION_SCRIPT`
  (`rsc_rspack_support.rb:40-44`) ALWAYS fails for `react-on-rails`/`react-on-rails-pro`:
  their `exports` maps do not export `./package.json`, so `require.resolve(pkg +
'/package.json')` throws `ERR_PACKAGE_PATH_NOT_EXPORTED` (verified against a real install;
  `@rspack/core` exports it, which is why the script works for rspack). Any node_modules tier
  must use the flat-read helper `rsc_flat_installed_package_version` only — ~1ms
  File.read/JSON.parse, verified to work through pnpm symlinks; no node spawn (~36ms) per boot.
- "If present" gating handles the environments cleanly: dev (all managers except Berry PnP) —
  tier applies, exactly the population that hits the drift; Berry PnP — no node_modules → skip →
  lockfile tier (#5049 adds Berry); pruned production / fresh checkout — falls through; monorepo
  hoisting — flat read misses → lockfile fallback. Required guard: the tier must stay behind the
  existing `local_path_or_url_version?` / workspace exemptions or the repo's own dummy apps
  (`workspace:`/`file:` links, installed version `17.0.0-rc.6`) would newly fail CI boot.
- Philosophy question settled by the project itself: issue #5049 says "the _installed_ version
  is what gets checked", and doctor prefers installed-over-declared for other packages. When
  node_modules is present it is a strictly better witness than the lockfile; the lockfile
  remains the right proxy when absent. Note node_modules is not ground truth in production
  either — what runs is what was compiled into bundles at build time.
- Likelihood moderate in team dev workflows; severity low-medium (confusing downstream errors,
  not silent corruption).

**Decision: separate follow-up issue/PR (difficulty S, ~0.5 day), plus a troubleshooting docs
entry now.** A resolution-hierarchy change alters boot behavior for ALL package managers and
deserves its own review, release note, and spec surface; it is a design input to #5049, not a
blocker, and should land after #5049 reusing its fixtures.

File the follow-up with three concrete notes:

1. Reuse the flat-read helper, never the Node script (`ERR_PACKAGE_PATH_NOT_EXPORTED`);
   alternatively/additionally add `"./package.json": "./package.json"` to both packages'
   `exports` (only helps future majors).
2. Doctor's gem/npm match check (`system_checker.rb:225-248`) has the same blind spot and should
   adopt the same tier.
3. New true positives (stale node_modules failing boot where it passed before) are the intended
   behavior change — release-note it.

Docs entry meanwhile: "version check passed but runtime uses wrong version → run install; the
check reads lockfiles, not node_modules."

---

## Problem 4 — Yarn v1 parser returns the FIRST block naming the package, not the block matching package.json's spec

**Claim.** `version_from_yarn_lock` sets `in_package_block` on the first line matching
`/^"?<name>@/` and returns that block's version. Yarn v1 lockfiles legitimately contain multiple
top-level blocks for the same package when requested ranges are incompatible (yarn v1 never
force-dedupes), so a transitive requester's block can win → wrong version → false boot-blocking
mismatch or false pass.

**Verdict: CONFIRMED with executable repro; one directional correction.**

Evidence:

- Repro (parser code extracted verbatim and executed): package.json spec `^17.0.0`; yarn.lock
  blocks `react-on-rails@^16.0.2 → 16.9.1` and `react-on-rails@^17.0.0 → 17.0.0`; parser
  resolved **"16.9.1"** → false version-mismatch vs gem 17.0.0.
- The requested spec is available at the call site (`resolve_version` line 581 has it in hand)
  and is simply not passed to the parser (line 588).
- Ordering correction: yarn v1 sorts entries by raw char-code of the full `name@range` key —
  digits (0x30) < `^` (0x5E) < `~` (0x7E). So an _exact_ pin `react-on-rails@17.0.0` sorts
  BEFORE `react-on-rails@^16.0.0` and is accidentally correct; the bug fires when the app uses a
  caret/tilde range (`^17` loses to transitive `^16`; `~16.0.0` loses to `^16.1.0`). Both
  false-fail and false-pass are reachable.
- Secondary checks: multi-spec merged headers (`react-on-rails@^16.1.1, react-on-rails@^16.2.0:`)
  parse correctly today; npm-alias keys (`"ror-alias@npm:react-on-rails@^17.0.0":`) are invisible
  (returns nil → package.json fallback; exotic, acceptable).
- Bonus bug, same root cause: the loop's `break` exits the WHOLE scan, so a first block with no
  version line returns nil instead of trying later blocks.
- Likelihood LOW: needs yarn v1 + a second requester of the checked package. Published npm
  dependents of react-on-rails are essentially nonexistent; the one real transitive requester is
  `react-on-rails-pro` itself, but when Pro is in the app's deps the checker checks
  `react-on-rails-pro` instead (nothing depends on it transitively) — the Pro path is
  effectively immune. Realistic trigger: yarn v1 workspaces with an internal package pinning a
  different range. Impact when hit: boot-blocking false error, very hard to self-diagnose.
- No multi-block same-package fixture exists in the spec suite today
  (`spec/react_on_rails/fixtures/`: caret/exact/similar-packages/pro-caret/malformed only).

**Decision: FIX INSIDE THE #5049 PR (difficulty S, 2–4h incl. tests — nearly free).** #5049
rewrites this parser for Berry anyway, and Berry keys (`"react-on-rails@npm:^17.0.0"`) force
header-key tokenization regardless — spec matching is shared scaffolding, not extra work.

Fix design (FINAL — maintainer decision): pass `package_json_version` into the parser; on each
header line strip trailing `:`/quotes, split on `", "`, and select ONLY the block whose key list
contains the exact selector `"#{package_name}@#{requested_spec}"` (normalizing Berry's `npm:`
protocol prefix). **No name-only fallback**: if no block matches the exact selector, the
lockfile is treated as stale/unresolved for this package — the lockfile tier returns nil and
resolution falls to the package.json spec, with the error text noting that the lockfile has no
entry matching the current selector (likely out of date) and suggesting the detected manager's
install command. Never use the first same-name entry.

Mirror the same rule in every format that records the requested selector:

- Berry: entry key `"name@npm:<spec>"` must equal the package.json spec (after `npm:`
  normalization).
- pnpm 6.0/9.0: the dependency object's `specifier` field must equal the package.json spec;
  pnpm 5.4: the `specifiers:` map entry must match.
- bun.lock: `workspaces[""].dependencies[name]` must equal the package.json spec.
- npm v2/v3: `packages[""].dependencies[name]` (root package entry) must equal the spec;
  npm v1 records no requested selector — name-keyed entry accepted as-is (nothing to verify).
  Any selector mismatch ⇒ stale/unresolved ⇒ package.json fallback with the out-of-date
  diagnostic.

Tests: `multi_block_yarn.lock` fixture (selector-matching block chosen over earlier same-name
block); a "no selector match → unresolved → package.json fallback + stale-lockfile message"
example per format; the early-`break` scan-abort fix.

---

## Lockfile format versions — support matrix and policy

Every manager has revved its lockfile format. Investigated via web research plus locally
generated lockfiles (`/tmp/lockmx/*`, all with `react-on-rails@^16.1.1` → resolved 16.6.0):
npm 10 (`--lockfile-version 1|2|3`), corepack yarn 1.22.22 / 2.4.3 / 3.8.7 / 4.9.2, corepack
pnpm 7.33.7 / 8.15.9, local pnpm 10.33.4; bun via official blog/docs + a real-world bun.lock
(elysia). Ruby behavior verified with ruby 4.0.5 (`YAML.load_stream`, `JSON.parse`).

### Version history per manager (verified)

| Manager          | Version field                           | Values → writers                                                                                                                         | Shape relevant to version extraction                                                                                                                                                                                                                                                                                                                                                                                              |
| ---------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| npm              | `lockfileVersion` (Integer)             | 1 → npm 5-6; 2 → npm 7-8; 3 → npm 9-11 (current; **no v4 exists**, `--lockfile-version` caps at 3)                                       | v1: `dependencies.<name>.version`; v2: `packages` + legacy `dependencies` (both); v3: `packages["node_modules/<name>"].version` only. Existing code already handles all three. npm itself parses leniently ("always attempt to get whatever data it can").                                                                                                                                                                        |
| npm (shrinkwrap) | same                                    | `npm-shrinkwrap.json` — same format, npm PREFERS it over package-lock.json when present                                                  | same parser, add the filename to candidates.                                                                                                                                                                                                                                                                                                                                                                                      |
| Yarn classic     | header `# yarn lockfile v1`             | only one version ever                                                                                                                    | line-based blocks, `version "x"` quoted.                                                                                                                                                                                                                                                                                                                                                                                          |
| Yarn Berry       | `__metadata.version` (Integer)          | 4 → yarn 2.4; 5, 6 → yarn 3.x (3.8 = 6); 7 → late 3.x; 8 → yarn 4.x                                                                      | Entry shape EMPIRICALLY IDENTICAL across 4/6/8: `"name@npm:range":` key, `version:` and `resolution: "name@npm:X.Y.Z"` fields. Real YAML → parse with Psych, not line regex; ignore `__metadata.version`.                                                                                                                                                                                                                         |
| pnpm             | `lockfileVersion` (Float, then String!) | 5.4 (Float) → pnpm 7; '6.0' → pnpm 8; '9.0' → pnpm 9 AND 10; '9.0' **multi-document** → pnpm 11 (env doc first, `---`, then project doc) | 5.4: top-level `dependencies: name: "16.6.0"` (string; `_peer` suffix form) + separate `specifiers`; 6.0: `dependencies: name: {specifier, version}` with `(...)` peer suffix; 9.0: same objects under `importers: .:`. Peer suffixes NEST: `16.6.0(react-dom@19.3.0(react@19.3.0))(react@19.3.0)` → cut at first `(` or `_`. One shape-dispatching extractor handled all three locally without reading `lockfileVersion` at all. |
| bun              | `lockfileVersion` (Integer)             | 0 → bun 1.1.39 opt-in; 1 → bun 1.2-1.3; 2 (+`configVersion`) → bun 1.4+, **no on-disk shape change**                                     | JSONC — trailing commas THROUGHOUT (verified on a real bun.lock); `JSON.parse` fails; a `,(\s*[}\]])` strip fixes it (comments also allowed by format, strip too). `packages[name][0]` = `"name@version"`; spec at `workspaces[""].dependencies`. Nested keys like `"a/b"` for conflicts.                                                                                                                                         |
| bun (binary)     | n/a                                     | `bun.lockb` ≤ 1.1 era                                                                                                                    | undocumented binary — do not parse.                                                                                                                                                                                                                                                                                                                                                                                               |

### Two Ruby gotchas (verified locally)

1. **pnpm 11 multi-doc:** `YAML.safe_load` silently returns ONLY THE FIRST document — the
   env/integrity doc, which has no `importers` — no exception raised. A naive parser silently
   resolves nothing (the exact "silently treated as no lockfile" failure class of #5049). Must
   use `YAML.load_stream` and select the document containing `importers`/`dependencies`.
   (pnpm ≥10.33 also accepts the multi-doc form, so it can appear in pnpm 10 repos.)
2. **bun trailing commas:** strict `JSON.parse` fails (`expected object key, got '},'`);
   the one-line sanitizer + `packages[name][0].split("@").last` works.

### Decision: support all live versions via SHAPE-dispatch, never version-gating

Answer to "all versions / a range / one version": **all currently-live versions per manager**,
selected by document shape rather than by the version field, with graceful fallback:

- npm: lockfileVersion 1, 2, 3 (already works) + `npm-shrinkwrap.json` filename.
- Yarn classic: v1 (the only version).
- Yarn Berry: `__metadata.version` 4-8 — one Psych-based parser, version field ignored.
- pnpm: 5.4 / 6.0 / 9.0 incl. multi-document — one extractor: pick importers doc if present,
  `importers["."]` else top-level `dependencies`, Hash entry → `["version"]` else String,
  strip from first `(` or `_`. (5.4 support costs ~3 lines; pnpm 7 is EOL but its lockfiles
  persist in repos.)
- bun: `bun.lock` versions 0/1/2 — one parser (JSONC-sanitize → JSON). `bun.lockb`: NOT
  parsed → package.json fallback; docs note the official migration
  (`bun install --save-text-lockfile --frozen-lockfile --lockfile-only`, bun ≥ 1.1.39).

Rationale for never hard-gating on the version number:

1. A version allow-list recreates bug #5049 on every future bump: bun 2 changed nothing on
   disk; pnpm 10 kept '9.0'; npm hasn't bumped since 2022. Treating an unknown number as
   "no lockfile" would suddenly boot-fail caret users when their manager updates.
2. Empirically the version number was never needed: shape-dispatch alone handled npm 1/2/3,
   Berry 4/6/8, pnpm 5.4/6.0/9.0 in the local matrix.
3. The failure mode is already defined and safe: extraction fails → nil → next candidate →
   package.json spec; never raise on lockfile content (matches today's
   `rescue JSON::ParserError`). Add a debug log when a lockfile exists but yields nothing.
4. Version fields have inconsistent TYPES (pnpm Float 5.4 vs String '6.0'/'9.0'; bun/npm/Berry
   Integer) — one more reason they make poor dispatch keys.

Fixture bonus: the generation matrix above doubles as the spec fixture set — every manager
resolved the same `package.json` (`^16.1.1`) to the same version (16.6.0), which is exactly
the cross-manager agreement spec the issue checklist calls for. Fixtures to check in: npm v1,
v2, v3; yarn classic; Berry v4 and v8; pnpm 5.4, 6.0, 9.0, 9.0-multi-doc; bun.lock v0 and v1
(+ trailing commas); one bun.lockb presence-only case.

---

## Diagnostic taxonomy for lockfile resolution (FINAL — maintainer decision)

Every message produced by the resolution layer must lead with the problem CLASS so users
immediately know which situation they are in: **missing**, **stale**, **ambiguous**, or
**unsupported**. Each message names the concrete file path(s), states expected vs found, and
gives the fix command for the detected manager.

Surfacing rule (two channels):

- When the strict package.json fallback then FAILS (range spec or gem mismatch), the class-
  prefixed diagnostic is embedded in the raised boot error, explaining WHY lockfile resolution
  did not apply.
- When the check still PASSES (exact matching pin), the diagnostic is emitted as
  `Rails.logger.warn` so the underlying hygiene problem stays visible without failing boot.

Implementation: resolution returns `(version, diagnostic)` — e.g. a small struct with
`code` (:missing / :stale / :ambiguous / :unsupported) and a pre-rendered message — consumed by
`validate_exact_version!` / `validate_version_match!` (embed in error) or warned otherwise.

### Message templates

**MISSING** — confident manager, no lockfile at all:

> Lockfile missing: no `pnpm-lock.yaml` found in `<dir>` for pnpm (detected via the
> `packageManager` field). The installed version cannot be verified, so the declared version in
> package.json is used.
> Fix: run `pnpm install` to generate the lockfile.

**STALE** — lockfile present but no entry matches the current exact selector (Problem 4 rule),
or its recorded selector differs from package.json:

> Lockfile stale: `<path>` has no entry matching `react-on-rails@^17.0.0` from package.json —
> the lockfile is out of date (package.json changed since the last install).
> Fix: run `yarn install` to update it.

Variant (confident manager, foreign lockfiles present — warning only, never an error):

> Lockfile stale: ignoring `yarn.lock` — this app is managed by pnpm (`packageManager` field +
> `pnpm-lock.yaml` present); lockfiles from other package managers are presumed stale.
> Fix: delete `yarn.lock` to avoid confusion.

**AMBIGUOUS** — detection not confident; NO lockfile was consulted:

> Lockfile ambiguity: cannot determine which package manager owns this app. Found `yarn.lock`
> AND `package-lock.json` in `<dir>`, and package.json has no `packageManager` field. No
> lockfile was used to resolve the installed version.
> Fix (any one):
>
> 1. Delete the stale lockfile(s) so only your real manager's lockfile remains.
> 2. Declare your manager in package.json, e.g. `"packageManager": "pnpm@10.0.0"`.
> 3. Pin the exact version: `<install cmd>`.

Variant (declared-vs-disk conflict):

> Lockfile ambiguity: package.json declares `packageManager: pnpm@9` but `pnpm-lock.yaml` is
> missing while `yarn.lock` exists. …same numbered fixes…

**UNSUPPORTED** — the detected manager's lockfile exists but cannot be read, three flavors:

- Binary by design (`bun.lockb`):
  > Lockfile unsupported: `bun.lockb` is a binary lockfile this gem cannot read.
  > Fix: migrate to bun's text lockfile:
  > `bun install --save-text-lockfile --frozen-lockfile --lockfile-only`, then delete
  > `bun.lockb` (requires bun >= 1.1.39).
- Unrecognized structure (likely a newer format version; shape-tolerant parsing found the file
  readable but its expected sections absent):
  > Lockfile unsupported: `<path>` (lockfileVersion: <v>) has an unrecognized structure — it
  > may be produced by a newer <manager> release than this gem knows. The declared version in
  > package.json is used instead. Please report this at
  > https://github.com/shakacode/react_on_rails/issues.
- Unparseable/corrupt (YAML/JSON error):
  > Lockfile unsupported: could not parse `<path>` (<error class>: <first line of message>).
  > Fix: re-run `<manager> install` to regenerate it, or restore the file.

Spec coverage: one example per class and flavor asserting the class prefix, the file path, and
the fix command appear in the raised error (range-spec case) and in the logged warning
(exact-pin case).

---

## Summary of decisions

| #   | Problem                                                   | Verdict                                                       | Decision                                                  | Difficulty |
| --- | --------------------------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------- | ---------- |
| 1   | Workspace lockfile hoisting (no walk-up)                  | Confirmed (severity: low-med, rising post-#5049)              | Follow-up PR + docs entry now; 2 structural asks in #5049 | M          |
| 2   | Fixed lockfile precedence / 3-way detection inconsistency | Confirmed (+ Rails.root bug in utils.rb)                      | **Fix in #5049 PR**                                       | S–M        |
| 3   | Lockfile-vs-installed drift (node_modules tier)           | Partially confirmed (fidelity gap; exports-map blocker found) | Follow-up issue/PR + docs entry now                       | S          |
| 4   | Yarn v1 first-block-wins parser bug                       | Confirmed with repro (+ bonus early-`break` bug)              | **Fix in #5049 PR**                                       | S          |

### Resulting #5049 PR scope

1. Issue checklist: pnpm-lock.yaml / bun.lock / Berry yarn.lock resolution with package.json
   fallback; decide `bun.lockb` (binary — decided: skip for version resolution, document the
   official text-lockfile migration); fixture-backed specs per format AND per format version
   (see the support matrix section: npm v1/v2/v3 + shrinkwrap, Berry v4/v8, pnpm 5.4/6.0/9.0
   incl. multi-doc, bun v0/v1) + cross-manager agreement spec; reconcile fallback error text
   with the relaxed rule via the diagnostic taxonomy section (class-prefixed messages:
   missing / stale / ambiguous / unsupported). Parsers are shape-dispatched, never
   version-gated.
2. Problem 2: trust-or-diagnose resolution (confident detection → ONLY that manager's lockfile,
   others never read; ambiguous detection → no lockfile consulted, strict package.json check
   with a diagnostic naming the ambiguity and fixes), with shared base-dir-aware detection;
   Berry-vs-v1 parser selection by content sniffing.
3. Problem 4: exact-selector matching required in ALL lockfile resolvers (yarn v1 + Berry block
   keys; pnpm `specifier`/`specifiers`; bun workspace spec; npm root-package spec where
   recorded) — no first-same-name-entry fallback; no match ⇒ lockfile stale/unresolved ⇒
   package.json fallback with out-of-date diagnostic; fix the early-`break` scan abort.
4. Problem 1 groundwork: single lockfile-candidates helper; importer-keyed pnpm parser.
5. Troubleshooting docs section covering Problems 1 and 3 (hoisted-lockfile workaround;
   "did you run install?" drift note).

### Follow-ups to file

- **Issue A (Problem 1):** upward lockfile discovery with workspace-root/`.git`/fs-root stop
  conditions; unify `detect_package_manager_from_lock_files` base dir (`Rails.root` →
  `node_modules_location`). (Ambiguity/stale-lockfile diagnostics are already covered in #5049
  by the trust-or-diagnose model of the Problem 2 fix.)
- **Issue B (Problem 3):** node_modules-first resolution tier via flat read (never the Node
  script — `ERR_PACKAGE_PATH_NOT_EXPORTED`); same fix for doctor's match check; consider
  exporting `./package.json` from both packages; release-note the behavior change.
