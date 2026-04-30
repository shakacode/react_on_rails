# Validating Node Renderer Changes

Manual validation checklist for changes under `packages/react-on-rails-pro-node-renderer/src/**`.

**Why this exists:** the Pro dummy app consumes the _built_ renderer at
`packages/react-on-rails-pro-node-renderer/lib/**`. Editing TypeScript under `src/` does
nothing until that lib output is regenerated, so a correct fix can look broken (or worse,
a regression can look fine because the dummy is still running stale lib output).

**Related:** [Manual Dev Environment Testing](manual-dev-environment-testing.md)

## When This Applies

If your PR touches **any** of these, run through the checklist below:

- `packages/react-on-rails-pro-node-renderer/src/**`
- `packages/react-on-rails-pro-node-renderer/package.json` (especially `protocolVersion`,
  `exports`, or runtime dependencies)
- Any worker pool, JWT auth, integrations (Sentry/Honeybadger), or VM-context code in the
  renderer

## Pre-flight: Toolchain

Ruby 3.3.x is the documented baseline for the Pro dummy app, and this workflow
has also been verified on Ruby 3.4.8. On Ruby 3.5+, the dummy's Gemfile pulls in
`ostruct`, `logger`, and `benchmark` as explicit gems for stdlib compatibility.
If a newer Ruby hits unrelated incompatibilities, fall back to the documented
Ruby version.

```bash
cd react_on_rails_pro/spec/dummy
bundle install

# Optional fallback if your local Ruby fails:
mise shell ruby@3.3.7  # or rbenv/asdf equivalent
bundle install
```

## Step 1: Rebuild the Renderer Package

Pick **one** of these depending on how you plan to iterate:

**One-shot rebuild (recommended for a single validation pass):**

```bash
pnpm --filter react-on-rails-pro-node-renderer run build
```

**Or use the dummy's convenience script:**

```bash
cd react_on_rails_pro/spec/dummy
pnpm run node-renderer:fresh   # builds, then starts the renderer standalone
```

This starts the renderer in the foreground on port 3800. For a full-stack dummy
run, either stop it before Step 2 and let `bin/dev` start the renderer, or leave
it running and comment out the `node-renderer:` line in `Procfile.dev` before
running `bin/dev`.

**Watch mode (recommended when iterating on the renderer source):**

Either uncomment the `node-renderer-build` line in `react_on_rails_pro/spec/dummy/Procfile.dev`,
or in a separate terminal run:

```bash
pnpm --filter react-on-rails-pro-node-renderer run build-watch
```

> If you skip this step, the dummy app will silently keep using the previous lib build.
> Symptoms: a fix you just applied does not change behavior, or a regression you expected
> to see does not appear.

## Step 2: Start the Dummy App

```bash
cd react_on_rails_pro/spec/dummy
bin/dev
```

Verify:

- [ ] `bin/dev` starts without `overlay.sockPort should be a number` (webpack-dev-server)
- [ ] `bin/dev` starts without `cannot load such file -- ostruct` (Rails precompile)
- [ ] All Procfile.dev processes are healthy after 30 seconds
- [ ] The `node-renderer` process logs that it bound to port 3800

## Step 3: Exercise the SSR Endpoints

For PRs touching streaming, hydration, RSC, or VM-context code, hit the routes that
actually exercise the renderer (not just static pages):

- [ ] `http://localhost:3000/stream_native_metadata` — renders without `ReferenceError`
      (e.g. `performance is not defined`) in the renderer logs
- [ ] `http://localhost:3000/hybrid_metadata_streaming` — same
- [ ] Any route specifically related to your change

For each route:

- [ ] Page returns 200 and renders SSR content (view-source shows component markup)
- [ ] No errors in the `node-renderer` Procfile pane
- [ ] No errors in the Rails server log
- [ ] No errors in the browser console

## Step 4: Confirm You Tested the New Code

It is easy to validate stale lib output without realizing it. Confirm:

- [ ] The built `lib/` file corresponding to your edit is newer than the `src/`
      file you changed. Compare the specific files with `stat` or use a
      per-file freshness check, for example:
      `find packages/react-on-rails-pro-node-renderer/lib -newer packages/react-on-rails-pro-node-renderer/src/<changed-file>.ts | head`
- [ ] If you used watch mode, you saw a rebuild line in the watcher output after your
      most recent edit
- [ ] Restart the `node-renderer` Procfile process after the rebuild — `node` does not
      hot-reload required modules

## Reporting Results in the PR

```markdown
## Node Renderer Validation

- [x] Rebuilt `react-on-rails-pro-node-renderer` package
- [x] Verified the rebuilt `lib/` file is newer than the changed `src/` file
- [x] `bin/dev` starts cleanly
- [x] `/stream_native_metadata` renders without errors
- [x] `/hybrid_metadata_streaming` renders without errors
- [x] No errors in node-renderer logs
```

If you cannot validate manually (e.g. no local Ruby toolchain), say so explicitly and
note that the change is type-checked / unit-tested only.
