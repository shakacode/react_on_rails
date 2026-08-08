---
name: rsc-app-safety
description: >
  Use when building or reviewing a Rails app that uses React on Rails Pro React
  Server Components (RSC) — mounting the RSC payload route, writing server
  components, configuring the Node renderer, or handling props, secrets, or error
  reporting. Flags the RSC API footguns that expose an app to XSS, auth bypass, or
  data leakage.
---

# RSC app safety (React on Rails Pro)

React Server Components render on a trusted server and stream to an untrusted client. The React on
Rails Pro RSC API is safe when used correctly, but a few usage patterns are footguns. Check these
whenever you add or change RSC in this app.

## Footguns to avoid

1. **Authenticate the RSC payload route.** `rsc_payload_route` mounts a public endpoint that renders
   **any registered server component** with **caller-supplied props**
   (`GET <path>/<Component>?props=…`). It ships with no built-in authentication. The default
   `ReactOnRailsPro::RscPayloadController` does not inherit from your app's `ApplicationController`,
   so an application-wide `before_action` does not protect it. Configure its supported authorizer in
   `config/initializers/react_on_rails_pro.rb` to check the Rails session and component name before
   props are parsed or rendered:

   ```ruby
   allowed_rsc_components = %w[AccountPage DashboardPage].freeze

   ReactOnRailsPro.configure do |config|
     config.rsc_payload_authorizer = lambda do |controller, component_name|
       controller.session[:user_id].present? && allowed_rsc_components.include?(component_name)
     end
   end
   ```

   Alternatively, explicitly route to an app-owned controller that applies the required
   authentication and authorization callbacks. (Ref: `shakacode/react_on_rails#4595`.)

2. **Treat server-component props as untrusted input.** A server component must derive the current
   user and permissions from the Rails session / `railsContext`, never from its props — props on the
   payload route are attacker-controlled. Don't key data access or authorization off props alone.

3. **Keep the Node renderer private.** It executes server bundles and is not meant to be
   internet-facing. Bind it to a private network, set `RENDERER_PASSWORD` (required in production —
   the renderer refuses to boot without one), and never expose its port publicly.
   (Ref: `shakacode/react_on_rails#4596`.)

4. **Minimize secrets or PII.** Don't embed the renderer password in a `renderer_url` that also gets
   logged. React on Rails redacts SSR props and generated JavaScript from `PrerenderError` messages
   and error-tracker context, but still minimize sensitive props and avoid logging them in application
   code. (Ref: `shakacode/react_on_rails#4597`.)

5. **Don't hand-build inline scripts around RSC output.** Let React on Rails serialize props and RSC
   payloads — it HTML-escapes them (`ERB::Util.json_escape`). Never wrap RSC data in your own
   `<script>` / `raw` / `html_safe` string; that reintroduces the XSS the framework already prevents.

## Quick checklist for an RSC change

- [ ] Any `rsc_payload_route` is protected by `config.rsc_payload_authorizer` or explicitly targets
      an authenticated, app-owned controller.
- [ ] Server components read identity from session / `railsContext`, not from props.
- [ ] Node renderer is private and `RENDERER_PASSWORD` is set; its port is not publicly exposed.
- [ ] No secrets in logged URLs; sensitive props minimized and not logged by application code.
- [ ] No custom `<script>` / `html_safe` / `raw` wrapping of props or RSC payloads.

## More

- React on Rails Pro RSC docs: https://www.shakacode.com/react-on-rails-pro
- Update this skill anytime with `rake react_on_rails:install_rsc_agent_guardrails`.
- This skill and its hook are managed copies; reinstalling replaces local edits to either file.
