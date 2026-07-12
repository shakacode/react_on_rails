---
name: rsc-guardrails
description: >
  Use when adding, editing, or reviewing React Server Components (RSC) code in
  React on Rails or React on Rails Pro — inline payload injection and streaming,
  the Node renderer, client-reference/manifest resolution, RSC controllers and
  routes, or props/console/error serialization. Covers the security and
  cross-request-isolation invariants that RSC changes must not regress.
---

# RSC Guardrails (framework internals)

RSC spans a **trusted server → untrusted client** boundary. A handful of invariants keep that
boundary safe. Most live in one owner file each; the risk is a well-meaning change quietly
breaking one. **Preserve every invariant below, and when you add a new surface, add its guardrail
in the same change.** When in doubt, the audit issues [#4595], [#4596], [#4597] are the worked
examples.

## Invariants (do not regress)

1. **Inline `<script>` / payload emission goes through `createScriptTag` → `escapeScript`.**
   Never hand-build a `<script>…</script>` string that contains flight-payload bytes, props, or any
   user-derived data. `escapeScript` (in `packages/react-on-rails-pro/src/injectRSCPayload.ts`)
   neutralizes `</script` and `<!--`; combined with `JSON.stringify` it blocks HTML/JS breakout.
   A payload chunk is user-controlled (usernames, comments). Regression test:
   `packages/react-on-rails-pro/tests/injectRSCPayload.test.ts` (breakout-escaping case).
   Nonces must pass through `sanitizeNonce` before landing in an attribute.

2. **No per-request data in module scope on server-render paths.** On the Node SSR server, a
   module-level `let`/`Map`/`Set`/object is shared across _all_ concurrent users' requests. Per-request
   RSC state (payloads, props, trackers, caches) must be request-scoped: instantiate per render
   (e.g. `new RSCRequestTracker(...)`), hold it in React `useRef`, or thread it through arguments —
   never a module-level mutable singleton. Module scope is only for build-config caches keyed by a
   build artifact (e.g. manifest-by-filename). See PRs #4574 / #4550 for what breaks this.

3. **Module / client-reference resolution stays on the allow-list.** Resolve a flight-payload module
   ID only through React's webpack/rspack manifest (the build-time allow-list). Never `require()` /
   `import()` a path, name, or specifier derived from payload or request content. The unbundled
   decode path is deliberately disabled (it throws) — keep it that way.

4. **Every client-reachable render entrypoint needs an auth story, and request props are untrusted.**
   A route/controller that renders a component from `params` (name or props) is a public API unless
   the host app adds authentication. Server components must derive identity from the Rails session/
   `railsContext`, never from props. When you add such an entrypoint, ship an auth hook + a docs
   warning ([#4595]).

5. **Keep secrets and PII out of logs and error context.** Do not log the renderer password, the
   `renderer_url` (it may embed credentials), the auth password, or raw props/`js_code`. Mask before
   logging; offer redaction for error-tracker context ([#4597]).

6. **The Node renderer is RCE-by-design once authenticated** (it runs client-supplied JS via `vm`;
   `vm` is not a sandbox). The trust boundary is _shared password + network isolation_. Don't widen
   it: keep the default bind private, keep the production password requirement (`process.exit(1)`
   without one), authenticate before any bundle write/execute, and don't add unauthenticated routes
   that read files or run code ([#4596]).

## PR review checklist

- [ ] New inline script/markup emission routes through `createScriptTag`/`escapeScript` (and nonce via `sanitizeNonce`).
- [ ] No new module-level mutable state holds per-request/per-user data on a server-render path.
- [ ] No `require`/`import` of a payload- or request-derived module id/path.
- [ ] New render route/controller has an auth story; server components don't trust props for authz.
- [ ] No secret/PII (password, `renderer_url`, props, `js_code`) added to logs or error context.
- [ ] New Node-renderer route authenticates before doing file/exec work; no `fileSize: Infinity` without a cap.

## Red flags — stop and reconsider

- Building a `` `<script>${something}</script>` `` string by hand in RSC/streaming code.
- `let x = new Map()` (or `= {}` / `= []`) at module top-level in a file that runs during server render.
- `require(`/`import(` with a variable that traces back to a request, payload, or manifest value.
- A new controller `include`ing an RSC renderer or a `*_route` helper with no `before_action`.
- `logger.*("… #{password | renderer_url | props | js_code} …")`.

## Reference

- Escaping: `packages/react-on-rails-pro/src/injectRSCPayload.ts` (`escapeScript`, `createScriptTag`), `packages/react-on-rails/src/sanitizeNonce.ts`.
- Request-scoping: `packages/react-on-rails-pro/src/RSCRequestTracker.ts`, `RSCProvider.tsx`, `RSCPrefetchStore.ts`.
- Reference resolution: the `react_on_rails_rsc` package (`clientReferences.ts`, `flight-server.node*.ts`).
- Node renderer: `packages/react-on-rails-pro-node-renderer/src/worker/authHandler.ts`, `worker.ts`, `worker/vm.ts`, `shared/configBuilder.ts`.
- Ruby serialization: `react_on_rails/lib/react_on_rails/json_output.rb` (`ERB::Util.json_escape`), `helper.rb`.

[#4595]: https://github.com/shakacode/react_on_rails/issues/4595
[#4596]: https://github.com/shakacode/react_on_rails/issues/4596
[#4597]: https://github.com/shakacode/react_on_rails/issues/4597
