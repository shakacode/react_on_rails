# Strict Content Security Policy (CSP)

React on Rails Pro's streaming SSR and React Server Components inject inline `<script>` tags into the HTML stream — RSC Flight payload chunks, per-component initialization scripts, console-replay scripts, immediate-hydration scripts, and React's own Suspense-boundary completion scripts. Under a strict Content Security Policy with **no `'unsafe-inline'`**, the browser executes an inline script only when it carries a `nonce` matching the response's CSP header.

React on Rails Pro threads Rails' own per-request CSP nonce (`content_security_policy_nonce`) through the entire streaming pipeline, so a strict policy like:

```text
script-src 'self' 'nonce-<per-request-value>'
```

works end to end: the page streams, every injected inline script executes, and hydration completes with zero CSP violations. This is verified continuously by an E2E test (`react_on_rails_pro/spec/dummy/e2e-tests/strict_csp.spec.ts`) that loads a streamed RSC page under the strict policy enforced in the Pro dummy app and asserts zero `securitypolicyviolation` events plus successful interactive hydration.

Because the nonce comes from Rails' native CSP support, there is no framework-specific nonce mechanism to configure — it integrates with your app's existing `content_security_policy` initializer.

## The Rails Recipe

Configure a strict policy in `config/initializers/content_security_policy.rb`:

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self
    # Style nonces are not covered by React on Rails (see "Scope" below).
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https
  end

  # Per-request nonce for normal full-page navigation. Use a session-stable
  # generator instead when Turbo/Turbolinks keeps the original document policy.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

  # Append the nonce to script-src only.
  config.content_security_policy_nonce_directives = %w[script-src]
end
```

Notes:

- With a nonce generator configured and `script-src` in `content_security_policy_nonce_directives`, Rails appends `'nonce-…'` to the `script-src` directive of every response automatically.
- **Per-request vs. per-session nonce**: `SecureRandom.base64(16)` generates a fresh nonce per request. Use it for normal full-page navigations. If your app uses Turbo/Turbolinks visits that can load streamed SSR/RSC pages, prefer a session-based generator derived from the session ID without exposing the raw session ID, for example `->(request) { Digest::SHA256.hexdigest("csp-nonce-#{request.session.id}")[0, 32] }`. Add `require "digest"` when using this session-stable example. Executable inline scripts in Turbo-fetched pages carry the new response's nonce while the active document still enforces the original page's policy. React on Rails' inert JSON data tags and same-origin client bundle work with either nonce lifetime; the session-based preference applies to executable inline scripts in Turbo/Turbolinks-fetched streamed responses.
- Browsers ignore `'unsafe-inline'` for a directive once that directive contains a nonce, so adding it as a fallback for legacy browsers is harmless but does not weaken the policy in modern browsers.
- In production, configure CSP violation reporting (`report-uri` or `report-to`, often in report-only mode first) so nonce regressions show up before users report hydration failures.
- A development environment usually needs extra allowances for `webpack-dev-server` (the bundle origin, the HMR websocket, and `'unsafe-eval'` for eval-based source maps). See the Pro dummy app's initializer (`react_on_rails_pro/spec/dummy/config/initializers/content_security_policy.rb`) for a working example that stays strict in test/production.

## How the Nonce Flows

1. **Rails generates the nonce** per request via `content_security_policy_nonce_generator` and adds `'nonce-…'` to the `script-src` header.
2. **React on Rails reads it** with `content_security_policy_nonce(:script)` (helper `csp_nonce`) and adds it to the rails context as `railsContext.cspNonce`.
3. **The rails context travels to the renderer** inside the serialized rendering request (the node renderer receives it as part of the request body, so nothing is lost across the Rails → renderer boundary).
4. **The streaming pipeline applies it everywhere**:
   - `streamServerRenderedReactComponent` passes `nonce` to React's `renderToPipeableStream`, covering React's hydration bootstrap content and the inline Suspense-boundary completion scripts React injects while streaming.
   - `injectRSCPayload` adds `nonce="…"` to every script tag it generates: the RSC payload array initialization scripts, the Flight payload chunk scripts, rendering-diagnostic scripts, and streamed console-replay scripts.
   - The Ruby helpers add the nonce to the immediate-hydration scripts (`ReactOnRails.reactOnRailsComponentLoaded(...)` / `reactOnRailsStoreLoaded(...)`) and to the console-replay script tag.

The nonce value is sanitized before being emitted into HTML attributes (`sanitizeNonce`): base64/base64url characters including `+`, `/`, `_`, `-` and trailing `=` padding pass through unchanged (Rails-generated nonces are never altered), while anything that could break out of the attribute is stripped and a malformed value causes the nonce attribute to be omitted entirely rather than emitting an unsafe attribute.

## What Is (and Isn't) Nonce-Covered

| Emitted tag                                                                                  | Executable? | Nonce                                      |
| -------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------ |
| RSC payload init / chunk / diagnostic scripts (streamed)                                     | Yes         | Yes                                        |
| Console-replay scripts (streamed and non-streamed)                                           | Yes         | Yes                                        |
| Immediate-hydration scripts (`reactOnRailsComponentLoaded` / `reactOnRailsStoreLoaded`)      | Yes         | Yes                                        |
| React hydration bootstrap + Suspense completion scripts                                      | Yes         | Yes (via `renderToPipeableStream` `nonce`) |
| Component props tag (`<script type="application/json" class="js-react-on-rails-component">`) | No          | Not needed                                 |
| Rails context tag (`<script type="application/json" id="js-react-on-rails-context">`)        | No          | Not needed                                 |
| Redux store props tag (`<script type="application/json" data-js-react-on-rails-store>`)      | No          | Not needed                                 |

**Why the JSON data tags need no nonce**: `<script>` elements with a `type` attribute that is not a JavaScript MIME type are _data blocks_ — the browser never executes them, so CSP `script-src` does not apply. They exist purely as inert payloads that the (nonce-exempt, same-origin) client bundle reads during hydration. Leaving them un-nonced is intentional: it keeps cached/streamed markup free of per-request values wherever execution is not involved.

## Scope: `script-src` Only

This guarantee covers `script-src`. Strict `style-src` policies (nonced styles) are **not** covered: React 19's hoisted style precedence links and inline `<style>` usage need separate treatment, tracked in [issue #3862](https://github.com/shakacode/react_on_rails/issues/3862). Keep `'unsafe-inline'` (or hashes) in `style-src` for now if your pages use inline styles.

## Caching Caveats

Nonces are per-request values; caching renders per-request markup. Two distinct mechanisms interact differently with nonces:

### Fragment caching helpers re-stamp the nonce on every cache hit

`cached_react_component`, `cached_react_component_hash`, `cached_stream_react_component`, `cached_buffered_stream_react_component`, `cached_static_rsc_component`, and `cached_async_react_component` cache the **final rendered HTML** (for streaming: the full chunk array) under a cache key built from your `cache_key` option plus bundle digests. The cached markup includes executable inline scripts whose `nonce` attribute was stamped by the request that populated the cache.

Since [issue #5021](https://github.com/shakacode/react_on_rails/issues/5021) was fixed, the cache write records the originating request's nonce in a trailing framework marker, and a cache hit **re-stamps exactly the attributes that carry that originating nonce** with the serving request's nonce on the way out of the cache (for streamed replays, per chunk), so cached fragments execute under the response's own `script-src 'nonce-…'` policy. Matching the exact originating value — a per-request secret nobody else could know — means markup that arrived with any _other_ nonce value (for example attacker-influenced content rendered through an app-level HTML-injection bug) is never promoted to the live nonce, and unrelated cached text is never mutated. The component cache key also carries a `csp-nonce` segment whenever the request has a nonce, so entries rendered with a nonce are never shared with nonce-free requests (and vice versa) — flipping a nonce generator on or off faults the cache instead of serving unusable markup. `cached_static_rsc_component` additionally strips embedded RSC payload/bootstrap scripts that reference `REACT_ON_RAILS_RSC_PAYLOADS` before caching.

Three related cautions remain:

- **Re-stamping requires a valid current nonce.** If the serving request's nonce falls outside the base64/base64url shape (`[A-Za-z0-9+/_-]` plus optional trailing `=` padding), nothing is spliced into cached markup and the cached scripts keep their original nonce (which the browser will block). Rails' built-in generators always pass; keep custom generators within that alphabet.
- **Wrapping `redux_store` or `react_component` in a plain Rails `cache do … end` block** bypasses the Pro helpers' normalization entirely: the cached fragment keeps the originating request's nonce (and rails-context script) verbatim. Use the `cached_*` helpers instead of raw fragment caching around React on Rails helpers when nonces are enforced.
- **Third-party page/CDN caches** that store whole responses still serve stale nonces; that is outside the framework's control.

### Prerender caching never serves a stale nonce — but stops hitting

`config.prerender_caching` keys the cache on a digest of the full rendering request, which embeds the serialized rails context — including `cspNonce`. With a per-request nonce generator every request produces a different digest, so:

- **No stale nonce is ever served** from the prerender cache (the key changes whenever the nonce changes), but
- **The cache effectively never hits across requests** — a silent performance regression. Each request also writes a new entry, so cache storage churns.

**Recommendation**: with nonce-based CSP enabled, disable `prerender_caching` for streamed/SSR pages or accept that it is inert for them.

## Troubleshooting

**Components render but never hydrate; console shows "Refused to execute inline script".**
The nonce is not reaching the page. Check that both `content_security_policy_nonce_generator` _and_ `content_security_policy_nonce_directives` (including `script-src`) are configured — Rails only appends `'nonce-…'` to directives listed there. Confirm the response header contains `'nonce-…'` and that the inline script tags carry the same value.

**Third-party `<script src>` tags are blocked.**
Either allowlist the host in `script-src` or add the nonce to the tag: `javascript_include_tag "https://cdn.example.com/lib.js", nonce: true`. Watch out for Rails' automatic `Link: rel=preload` headers: a preload header cannot carry a nonce, so the preload itself violates `script-src-elem` even when the tag is nonced. Pass `preload_links_header: false` to `javascript_include_tag` for cross-origin scripts you authorize via nonce (same-origin preloads are covered by `'self'`).

**Inline event handlers (`onclick="…"`, `onchange="…"`) stop working.**
CSP nonces don't apply to inline event handlers. Move the logic into a nonced script (or external file) using `addEventListener`. Example: `javascript_tag nonce: true do ... end`.

**`blockedURI: "eval"` violations from the RSC client in development.**
React's _development_ Flight client (`react-on-rails-rsc` / `react-server-dom-webpack` development build) calls `eval` to reconstruct server-component stack frames for console replay and owner stacks. The call is wrapped in a try/catch, so under a no-`'unsafe-eval'` policy it degrades gracefully (less precise stack frames; nothing breaks). The production Flight client build contains no `eval`. If the noise bothers you in development, add `'unsafe-eval'` to `script-src` **in development only** — never in production.

**Streaming works but a fragment-cached component misbehaves under CSP.**
Cache hits re-stamp the originating nonce with the serving request's nonce (see [Caching Caveats](#caching-caveats) above), so first check the mechanisms that bypass or disable that re-stamp: a plain Rails `cache do … end` block around `react_component`/`redux_store`, a whole-response page/CDN cache, or a custom nonce generator whose current value falls outside the base64/base64url shape (which skips re-stamping entirely).

**Nonce appears to be dropped/missing from injected scripts.**
`sanitizeNonce` omits the nonce attribute if the value doesn't look like base64/base64url (this prevents attribute-injection attacks). Rails' built-in generators (`SecureRandom.base64`, session id) always pass. If you use a custom generator, keep its output within `[A-Za-z0-9+/_-]` plus optional trailing `=` padding.
