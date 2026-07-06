# Security Model and Hardening

> [!NOTE]
> **Summary for AI agents:** This page documents the React on Rails security model: how component props are escaped into HTML, the trust boundary and hardening options for the Pro Node renderer, and the React Server Components (RSC) advisory posture. For review-app-specific guidance, see [Review App Security](./review-app-security.md). To report a vulnerability, see [SECURITY.md](https://github.com/shakacode/react_on_rails/blob/main/SECURITY.md).

This guide is written for security reviewers. Every claim is tied to specific code in the
[shakacode/react_on_rails](https://github.com/shakacode/react_on_rails) repository so you can verify it
yourself; where a guarantee does **not** exist, that is stated explicitly.

Scope:

- [Props escaping contract](#props-escaping-contract) — applies to all React on Rails apps (OSS and Pro).
- [Node renderer threat model](#node-renderer-threat-model-pro) — applies to React on Rails Pro apps using the
  standalone Node renderer.
- [React Server Components advisory posture](#react-server-components-advisory-posture-pro) — applies to Pro
  apps using RSC.
- [Reporting vulnerabilities](#reporting-vulnerabilities).

Out of scope here: the general security of your own React components and Rails app (authentication,
authorization, CSRF, etc. remain standard Rails concerns — React on Rails does not add a separate
authentication or authorization layer in front of your Rails app).

## Props escaping contract

### How props reach the page

`react_component` and `redux_store` embed your props as JSON inside
`<script type="application/json">` data tags — not as executable JavaScript:

- Component props: `generate_component_script` in `react_on_rails/lib/react_on_rails/pro_helper.rb`
  (part of the OSS gem despite the file name) builds
  `content_tag(:script, json_safe_and_pretty(render_options.client_props).html_safe, type: "application/json", ...)`.
- Store props: `generate_store_script` in the same file does the same for Redux store hydration data.
- Rails context: `rails_context_if_not_already_rendered` in `react_on_rails/lib/react_on_rails/helper.rb`
  embeds the rails context the same way.

The client-side package reads these tags back with `JSON.parse` and passes the result to your components.

### What is escaped, and by what

All three paths above escape the JSON through one function:
`ReactOnRails::JsonOutput.escape`, which delegates to Rails'
`ERB::Util.json_escape` (`react_on_rails/lib/react_on_rails/json_output.rb`, line 8).

`ERB::Util.json_escape` replaces the HTML-significant characters `<`, `>`, and `&` with their Unicode
escape sequences (`\u003c`, `\u003e`, `\u0026`) and escapes the U+2028/U+2029 line separators. Because no
literal `<` can survive, a props value containing `</script><script>alert('xss')</script>` cannot terminate
the surrounding `<script>` tag — it is emitted as
`\u003c/script\u003e\u003cscript\u003ealert('xss')\u003c/script\u003e`, which `JSON.parse` later restores
to the original string for your component as plain data.

The helper entry points that apply this escaping:

- `sanitized_props_string` (`react_on_rails/lib/react_on_rails/helper.rb`) — escapes props whether passed
  as a `Hash` (serialized via `to_json` first) or as a pre-serialized JSON `String`.
- `json_safe_and_pretty` (`react_on_rails/lib/react_on_rails/helper.rb`) — same contract, used by the
  script-tag generators above.

### Test coverage

This contract is covered by specs in the repository:

- `react_on_rails/spec/react_on_rails/json_output_spec.rb` — unit specs for `JsonOutput.escape`, including
  an explicit `</script><script>...` payload.
- `react_on_rails/spec/dummy/spec/helpers/react_on_rails_helper_spec.rb` (`#sanitized_props_string`
  examples) — asserts that a props hash containing `</script><script>alert('foo')</script>` is escaped in
  the rendered output, for both hash and string-typed props.

### What this does and does not guarantee

**Guaranteed (by the code above):**

- Props values cannot break out of the JSON `<script type="application/json">` data tags, because `<`,
  `>`, and `&` never appear literally in the emitted JSON.
- Props are delivered to React as data. React's normal JSX text rendering then escapes them again on
  output, as in any React app.

**Not guaranteed — your responsibility:**

- **What your components do with props.** If a component passes a props value to
  `dangerouslySetInnerHTML`, interpolates it into a URL (`javascript:` schemes), or otherwise treats it as
  markup, the embedding-layer escaping above does not protect you. Escaping happens at the HTML-embedding
  boundary, not inside your component tree.
- **Pre-serialized string props are trusted as JSON.** If you pass props as a `String` instead of a
  `Hash`, React on Rails HTML-escapes it for the client-side script tag but does **not** validate that it
  is well-formed JSON. On the server-rendering path, the string is interpolated directly into the
  JavaScript evaluated by the SSR runtime (`var props = #{props_string};` in
  `react_on_rails/lib/react_on_rails/server_rendering_js_code.rb`; see also the comment above the
  `js_code` construction in `server_rendered_react_component` in
  `react_on_rails/lib/react_on_rails/helper.rb`, which only escapes U+2028/U+2029 there). A string built
  by concatenating untrusted input is therefore JavaScript injection into your own SSR context. **Build
  props from Ruby data structures (`Hash`); never concatenate user input into a JSON string yourself.**
- **Server-rendered HTML is inserted as-is.** The HTML your server-rendered components produce is marked
  `html_safe` and inserted without further sanitization — the output of your own bundle is trusted by
  design. The escaping contract covers props going _in_, not component HTML coming _out_.

## Node renderer threat model (Pro)

This section applies to React on Rails Pro deployments using the standalone Node renderer
(`react-on-rails-pro-node-renderer`). If you use ExecJS-based SSR (the OSS default), there is no separate
renderer process or network hop, and this section does not apply.

### Trust model: the renderer executes your app's code

The Node renderer is a service that accepts JavaScript bundles uploaded by your Rails app and executes
them to render components. This is its purpose, not a flaw — but it has a direct consequence:

> **Anyone who can reach the renderer's port and authenticate can execute arbitrary JavaScript with the
> renderer process's privileges** (by uploading a bundle, or by sending a rendering request that the
> bundle evaluates). The renderer is **not** a sandbox for untrusted code and must be treated as an
> internal service with the same trust level as your Rails app servers.

Concretely, the worker exposes these HTTP endpoints
(`packages/react-on-rails-pro-node-renderer/src/worker.ts`):

| Endpoint                                                                 | Auth                                                     | Purpose                                                     |
| ------------------------------------------------------------------------ | -------------------------------------------------------- | ----------------------------------------------------------- |
| `POST /bundles/:bundleTimestamp/render/:renderRequestDigest`             | password (via `performRequestPrechecks`)                 | Evaluate a rendering request; may also carry bundle uploads |
| `POST /bundles/:bundleTimestamp/incremental-render/:renderRequestDigest` | password (via `performRequestPrechecks`)                 | Streaming/incremental rendering                             |
| `POST /upload-assets`                                                    | password (via `performRequestPrechecks`)                 | Upload server bundles and assets                            |
| `POST /asset-exists`                                                     | password (via `authenticate`, no protocol-version check) | Check whether an uploaded asset exists                      |
| `GET /info`                                                              | **none**                                                 | Returns `node_version` and `renderer_version`               |

Note for reviewers: unlike the other authenticated endpoints, `/asset-exists` calls `authenticate`
directly rather than through `performRequestPrechecks`, so it skips the protocol-version check — a
compatibility control, not a security control.

Known limitation: `GET /info` is unauthenticated and discloses the Node and renderer versions
(`worker.ts`, the `app.get('/info', ...)` route). This is harmless on a private network but is version
disclosure if you expose the port publicly — one more reason never to do so.

### Network exposure

- The renderer binds to `localhost` by default (`host: env.RENDERER_HOST || 'localhost'` in
  `packages/react-on-rails-pro-node-renderer/src/shared/configBuilder.ts`). Setting `RENDERER_HOST=0.0.0.0`
  is needed for containerized deployments; if you do, network access control must come from your
  infrastructure (security groups, network policies, private VPC subnets).
- The renderer listens for **cleartext HTTP/2 (h2c)** and does not terminate TLS itself (see the server
  construction in `run()` in `worker.ts`). The shared password travels in the request body. Treat the
  Rails-to-renderer link as plaintext: keep it on a private network, or place TLS-terminating
  infrastructure in front of the renderer and use an `https://` value for `config.renderer_url` on the
  Rails side.
- **Never expose the renderer port to the public internet.** There is no rate limiting, no TLS, and the
  authenticated surface is "execute JavaScript".

### Authentication between Rails and the renderer

Authentication is a single shared secret:

- The renderer checks the password from the request body
  (`authenticate` in `packages/react-on-rails-pro-node-renderer/src/worker/authHandler.ts`). A
  submitted password whose byte length differs from the configured secret is rejected with `401`
  _before_ any comparison; only same-length candidates are then compared with
  `crypto.timingSafeEqual`. The comparison is therefore timing-safe for same-length guesses, but the
  early length check means the secret's length is not protected — use a long random secret, not a
  short passphrase. Comparison errors are also rejected with `401`.
- **Production-like environments fail closed on both sides.** If neither `RAILS_ENV` nor `NODE_ENV` is a
  development/test value, the renderer refuses to start without a password
  (`validatePasswordForProduction` in `configBuilder.ts`), and the Rails side raises at configuration time
  (`validate_renderer_password_for_production` in
  `react_on_rails_pro/lib/react_on_rails_pro/configuration.rb`). When both environments are unset, the
  code treats the environment as production-like and still requires a password.
- Both sides warn at startup if the password matches a known-default value or is shorter than 16
  characters (`KNOWN_WEAK_PASSWORDS` / `MIN_PASSWORD_LENGTH` in `configBuilder.ts`;
  `warn_if_renderer_password_weak` in the Pro gem's `configuration.rb`). In these audited paths the
  literal password value is not logged: the weak-password warnings report only length/known-default
  status, and the renderer masks the password in its config diagnostics. Other logging or
  error-reporting paths in your app (e.g. exception trackers capturing config objects) are outside
  this guarantee — audit them yourself.
- Rails resolves the password in this order: `config.renderer_password`, then a password embedded in
  `config.renderer_url` (`https://:password@host:3800`), then `ENV["RENDERER_PASSWORD"]`
  (documented in the error message in `configuration.rb`).

Known limitations of this model (by design — plan your network accordingly):

- One shared secret, not per-client credentials; there is no second factor and no built-in rotation
  mechanism. Rotate by deploying a new `RENDERER_PASSWORD` to both sides.
- In `development`/`test` environments the password is optional, and with no password set the renderer
  accepts unauthenticated requests (`authenticate` returns success when no password is configured). Do not
  run a password-less renderer outside an isolated development machine.
- Authentication grants access to all endpoints equally; there is no per-endpoint authorization.

### Code execution and the VM context

The renderer evaluates bundles inside a Node `vm` context. Two configuration options control how much of
the host the bundle can reach, and their security semantics are documented in the config source
(`packages/react-on-rails-pro-node-renderer/src/shared/configBuilder.ts`, `Config` interface):

- `supportModules: true` injects a default set of Node globals **and wraps the bundle so it receives the
  host `require`**, granting access to Node built-ins such as `fs` and `child_process`. This is required
  for loadable-components and most real-world SSR bundles.
- `additionalContext`: any plain-object value (even `{}`) also switches the bundle into CommonJS mode with
  the host's unrestricted `require`.
- The most restricted mode is `supportModules: false` **and** `additionalContext: null`.

Even in the most restricted mode, do not treat the `vm` context as a security boundary: Node's `vm` module
is explicitly [not a security mechanism](https://nodejs.org/api/vm.html) and the renderer makes no
sandboxing claim beyond it. The security boundary is **who can reach the port and authenticate**, plus the
OS-level privileges of the renderer process.

### Hardening checklist

Every item below maps to a configuration option or behavior verified in this repository:

1. **Set a strong `RENDERER_PASSWORD`** (random, ≥ 16 characters) on both Rails and the renderer.
   Production-like environments refuse to start without one; the length/known-default checks only warn.
2. **Keep the renderer on a private network.** Default bind is `localhost`; if you set
   `RENDERER_HOST=0.0.0.0` for containers, restrict ingress to your Rails app servers and your health
   checker.
3. **Treat the link as plaintext.** The renderer speaks cleartext h2c; use a private network or external
   TLS termination, and prefer an `https://` `config.renderer_url` when a TLS hop exists.
4. **Run the renderer as an unprivileged OS user / minimal container, with resource limits.** The
   bundle typically runs with host `require` (see above), so the renderer process's OS privileges and
   resource ceiling are the effective blast radius. Set `--max-old-space-size` on the Node process and
   enforce container `memory` + `cpu` limits to bound the impact of a rogue or compromised bundle.
5. **Don't expose `GET /info`** beyond your monitoring network; it is unauthenticated version disclosure.
6. **Rotate the shared secret on a schedule** by redeploying both sides with a new value; there is no
   built-in rotation.
7. **Keep `NODE_ENV`/`RAILS_ENV` set correctly.** The fail-closed password requirement keys off these; an
   unset environment is treated as production-like (strict), but a mistakenly set `development` value
   disables the requirement.

## React Server Components advisory posture (Pro)

RSC support in React on Rails Pro is built directly on React's Flight packages: the
`react-on-rails-rsc` package wraps React's `react-server-dom-webpack`. Vulnerabilities in those upstream
packages therefore apply to this stack, and the project's response is enforced in code:

- **December 2025 React RSC advisories.** The React team published critical advisories affecting React
  Server Components, including a remote code execution issue
  ([CVE-2025-55182](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components))
  and follow-on
  [denial-of-service and source-code exposure fixes](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components).
  React on Rails Pro shipped corresponding dependency floors; see the `CHANGELOG.md` security entries for
  CVE-2025-55182 ([PR 2175](https://github.com/shakacode/react_on_rails/pull/2175)) and
  CVE-2025-55183/55184/67779 ([PR 2233](https://github.com/shakacode/react_on_rails/pull/2233)).
- **The patched-version requirement is checked, not just documented.** For React on Rails Pro 17 RSC, the
  supported React range is `19.2.x` with patch `>= 19.2.7` (`~19.2.7`) and
  `react-on-rails-rsc >= 19.2.1` on the React 19 line:
  - `rake react_on_rails:doctor` warns when the installed React is below the supported patch floor and reports the
    Pro 17 RSC floor (`check_rsc_react_version` in `react_on_rails/lib/react_on_rails/doctor.rb`).
  - The RSC generator emits the same floor/coordination warning at setup time
    (`react_on_rails/lib/generators/react_on_rails/rsc_setup.rb`).
  - The Node renderer runs an RSC peer-compatibility check at startup (`runRscPeerCompatibilityCheck`,
    called from the renderer's master, worker, and wrapper entry points in
    `packages/react-on-rails-pro-node-renderer/src/`). Incompatible `react`, `react-dom`, or
    `react-on-rails-rsc` versions **fail startup**. Setting `REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK=1`
    downgrades the hard startup failure to a warning — **do not set this in production: it allows the renderer to
    boot below the verified React/RSC floor.**

### How to verify your own status

```bash
# Reports your React/RSC versions and flags the security floor:
bundle exec rake react_on_rails:doctor
```

Also subscribe to [React's blog](https://react.dev/blog) for upstream advisories, and watch this
repository's `CHANGELOG.md` security entries for the corresponding React on Rails releases.

## Reporting vulnerabilities

The supported-version policy, triage commitments, and private reporting process live in
[SECURITY.md](https://github.com/shakacode/react_on_rails/blob/main/SECURITY.md) at the repository root.
Formalizing the public advisory process (security contact alias, GitHub Security Advisories policy) is
tracked in [issue #3266](https://github.com/shakacode/react_on_rails/issues/3266).

## Related documentation

- [Review App Security](./review-app-security.md) — running untrusted PR code in review apps
- [Node Renderer Basics](../building-features/node-renderer/basics.md) — renderer architecture
- [Node Renderer JS Configuration](../building-features/node-renderer/js-configuration.md) — all renderer
  configuration options, including the `supportModules` / `additionalContext` runtime-globals notes
- [Docker Deployment](./docker-deployment.md) — containerized deployment patterns
