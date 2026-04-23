# Migrate From react-rails

This migration is easiest when the app is already on a modern Rails + Shakapacker baseline.

If you want repo-shaped references before touching your own app, start with
[Example Migrations](./example-migrations.md) and then come back here for the
mechanics.

## Pick the right first target

Not every `react-rails` app is a good candidate for a low-friction first migration. Before you start, classify what you have:

- **Rails-owned island mounts on Shakapacker 6+ and Rails 6+.** This is the smoothest path. The generator + the steps below usually get you there with small, localized edits. (Note: `server_bundle_output_path` auto-detection requires Shakapacker 9.0+; on 6–8, set it explicitly in the initializer.)
- **Webpacker-era apps (`gem "webpacker"`, Webpack 4).** Current React on Rails does not support Webpacker — `react_on_rails doctor` flags it as a removed breaking-change issue, and the gem requires `shakapacker >= 6.0`. You must migrate off Webpacker before installing current React on Rails. See [Preferred path for Webpacker-era apps](#preferred-path-for-webpacker-era-apps) below.
- **Client-routed SPA shells (Rails is mostly a shell around a React Router / TanStack Router app).** Render the top-level SPA component from one ERB view using `react_component` (or `react_component_hash` when SSR needs to return multiple regions such as `componentHtml`, `title`, and other head tags).
  - One `react_component` call mounts the whole app.
  - If you additionally want to break the SPA into several Rails-owned islands, treat that as a separate product decision rather than bundling it with the bundler/integration change.

The wrong first target usually leads teams to conclude "React on Rails is broken" when the real problem is legacy bundler compatibility, or to bundle a SPA re-architecture into what should have been a bundler migration.

## Choose a first slice

Pick a small first slice before you touch the whole app:

1. Prefer one Rails-owned page, island, or shell fragment over a broad page rewrite.
2. Good first wins are often maintainability-first: replacing `ReactRailsUJS` on one low-risk mount, splitting a large shell into smaller boundaries, or moving one legacy Rails page behind a documented helper path.
3. The first PR does not need to eliminate every `react_component` call. It only needs to prove that one mount can move cleanly.

## Preferred path for Webpacker-era apps

If the app still uses `gem "webpacker"`, the recommended path is:

1. **Migrate to Shakapacker first, as its own PR.** Keep the bundler change separate from the React on Rails change. This makes each step reviewable and isolates any compatibility issues. See the [Shakapacker v6 upgrade guide](https://github.com/shakacode/shakapacker/blob/v6.6.0/docs/v6_upgrade.md) for the concrete Webpacker → Shakapacker steps.
2. **Then run the React on Rails install generator** against the Shakapacker-based app.

The generator is not designed to bridge Webpack 4 + Webpacker to current React on Rails defaults for you — it assumes a Shakapacker baseline. If you cannot migrate off Webpacker yet, pin `react_on_rails` to `~> 14.2` (v15.0.0 is retracted; v16 is the release that removed Webpacker support) rather than trying to use current React on Rails with Webpacker.

## Preflight

Before swapping gems, check these first:

1. **Webpacker vs Shakapacker**: if the app still uses `webpacker`, see [Preferred path for Webpacker-era apps](#preferred-path-for-webpacker-era-apps) above.
2. **Bundler age**: some older `react-rails` apps still carry Bundler 1.x lockfiles. Those can fail on modern Ruby before you even reach the migration work.
3. **Rails age**: current `react_on_rails` requires Rails 5.2+. Rails 5.1 / Webpacker 3 apps are usually a staged migration, not a one-command migration.
4. **Package manager metadata**: if you have `yarn.lock`, `pnpm-lock.yaml`, or `bun.lock*`, ensure `package.json` has a matching `packageManager` field (for example `npm@10.9.2`, `yarn@1.22.22`, `pnpm@10.12.1`, or `bun@1.2.13`).
5. **Browserslist source**: use one source only. If `.browserslistrc` exists, remove `browserslist` from `package.json`.
6. **JSX-in-.js projects**: current install generator auto-switches to Babel when JSX is detected in `.js` files. If your project has custom transpiler setup, review `config/shakapacker.yml` after generation.
7. **`react_component` helper collision**: if you plan to keep `react-rails` installed during a staged migration, read [Coexistence: keeping both gems installed during a staged migration](#coexistence-keeping-both-gems-installed-during-a-staged-migration) before adding `react_on_rails`. Both gems define a `react_component` view helper with incompatible signatures; once `react_on_rails` is present, its helper takes precedence in all views regardless of gem load order.

If you are already on `shakapacker` 7+ and React 18+, the migration is mostly about helper syntax, component registration, and generated defaults.

If `bundle install` fails before you even start because the lockfile was generated by Bundler 1.x, refresh the lockfile with a modern Bundler first:

```bash
bundle _2.3.26_ lock --update
bundle _2.3.26_ install
```

If `package.json` is missing `packageManager`, set it to your project's actual manager and exact version before running install generators:

```bash
# pick the one that matches your lockfile
npm pkg set packageManager='npm@10.9.2'
npm pkg set packageManager='yarn@1.22.22'
npm pkg set packageManager='pnpm@10.12.1'
npm pkg set packageManager='bun@1.2.13'
```

1. Update Deps
   1. Replace `react-rails` in `Gemfile` with `react_on_rails` and make sure `shakapacker` is present.
   2. Remove `react_ujs` from `package.json`.
   3. Run `bundle install` and your package manager's install command.
   4. Commit changes.

2. Run `rails g react_on_rails:install` but do not commit the change. `react_on_rails` attempts to install node dependencies, creates a sample React component, Rails view/controller, and updates `config/routes.rb`. If dependency installation fails, the generator prints manual install commands. If required package-manager tooling (Node.js and npm/yarn/pnpm/bun) is unavailable, the generator stops with setup guidance. Run the suggested commands or install missing tools before continuing.

3. Adapt the project: Check the changes and carefully accept, reject, or modify them as per your project's needs. Besides changes in `config/shakapacker` or `babel.config` which are project-specific, here are the most noticeable changes to address:
   1. Check Webpack config files at `config/webpack/*`. If coming from `react-rails` v3 on Shakapacker, the changes are usually localized. The most important difference is the server bundle entrypoint: `react-rails` commonly uses `server_rendering.js`, while React on Rails defaults to `server-bundle.js`.

   2. In `app/javascript` directory you may notice some changes.
      1. `react_on_rails` can work with manual registration or the newer auto-bundling flow. Auto-bundling is usually the cleaner target for new work.

      2. `react_on_rails` uses `server-bundle.js` instead of `server_rendering.js`. If you keep your old filename, update the generated config accordingly.

      3. Replace `ReactRailsUJS` mounting with explicit React on Rails registration. The generated files show the current registration pattern.

   3. Check Rails views. In `react_on_rails`, `react_component` view helper works slightly differently. It takes two arguments: the component name, and options. Props is one of the options. Take a look at the following example:

      ```diff
      - <%= react_component('Post', { title: 'New Post' }, { prerender: true }) %>
      + <%= react_component('Post', { props: { title: 'New Post' }, prerender: true }) %>
      ```

4. Validate before final cleanup:
   1. Confirm that old `react_ujs` references are gone:

      ```bash
      rg -n "react_ujs|ReactRailsUJS|server_rendering\.js" app/javascript app/assets app/views config
      # or without ripgrep:
      grep -rn "react_ujs\|ReactRailsUJS\|server_rendering\.js" app/javascript app/assets app/views config
      ```

   2. Ensure compile succeeds:

      ```bash
      bundle exec rails shakapacker:compile
      ```

   3. Review `react_component` helper calls to ensure they use options-style props:

      ```bash
      rg -n "react_component\\b" app/views
      # or without ripgrep:
      grep -rEn "react_component\\b" app/views
      ```

      These commands list candidates only. Inspect each match manually and convert any legacy positional calls
      (for example `react_component('Post', @props, prerender: true)`, `react_component 'Post', @props`,
      `react_component :Post, @props`, or `react_component component_name, @props`) to options-style props
      before running tests.

   4. Run your test suite and fix any app-specific breakages before merging.

## Legacy compatibility fixes that often make migration one-shot

Older `react-rails` apps frequently need these additional fixes after the generator run:

1. Remove old UJS mounting from legacy packs (`app/javascript/packs/application.js` and related files).

   Remove patterns such as:

   ```js
   var componentRequireContext = require.context('components', true);
   var ReactRailsUJS = require('react_ujs');
   ReactRailsUJS.useContext(componentRequireContext);
   ```

2. If you are switching to React on Rails `server-bundle.js`, remove stale `app/javascript/packs/server_rendering.js` usage.

3. Update existing ERB helper calls from old positional props to options-style props:

   ```diff
   - <%= react_component 'Post', @props, prerender: true %>
   + <%= react_component('Post', { props: @props, prerender: true }) %>
   ```

4. If server bundles are not being found, verify `config/initializers/react_on_rails.rb` setup:
   - On Shakapacker 9.0+, React on Rails usually auto-detects the output path from `private_output_path`. Leave this unset unless you intentionally need an override.
   - On older setups, you may need an explicit value:

   ```ruby
   config.server_bundle_output_path = "ssr-generated"
   ```

5. If `spec/rails_helper.rb` gets a malformed merge after generator updates, keep a single valid `RSpec.configure do |config| ... end` block and include:

   ```ruby
   ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
   ```

For published repo examples, including older and Rails 7-era `react-rails` migrations, see [Example Migrations](./example-migrations.md).

## Coexistence: keeping both gems installed during a staged migration

Large apps often cannot swap every `react-rails` mount in a single PR. If you need `react-rails` and `react_on_rails` installed side-by-side while you migrate views incrementally, plan for the `react_component` helper collision **before** adding the gem.

### Why it collides

Both gems ship a view helper named `react_component` that ends up available in Rails views:

- `react-rails` (`React::Rails::ViewHelper`) takes positional arguments: `react_component(name, props, html_options)`.
- `react_on_rails` (`ReactOnRailsHelper` → `ReactOnRails::Helper#react_component`) takes `react_component(name, options = {})` where props are nested under `options[:props]`.

`react-rails` includes `React::Rails::ViewHelper` directly into `ActionView::Base` from its railtie. `react_on_rails` ships `ReactOnRailsHelper` as a normal Rails helper module, and under Rails' default `include_all_helpers` behavior that helper is pulled into the controller/view helper module that sits earlier in method lookup than `ActionView::Base`. In a standard Rails app, that means `ReactOnRailsHelper#react_component` wins once the gem is present. This is a helper-precedence issue, not `app/helpers/` file order or gem-name alphabetics. If your app customizes helper loading, verify which helper owns `react_component` before relying on coexistence.

Once you add `react_on_rails` to the `Gemfile`, every existing legacy call starts resolving to `ReactOnRails::Helper#react_component(name, options = {})`, which behaves differently depending on how many positional arguments you pass. As of Rails 7/8, Rails gives no boot-time warning in either case:

- **Three or more positional arguments** — e.g. `react_component "command_bar/CommandBar", props, { camelize_props: false }` — raise `ArgumentError` at render time on the first request to any un-migrated view, because the new helper only takes two arguments.
- **Two positional arguments** — e.g. `react_component "command_bar/CommandBar", props` — are silently accepted. The `props` hash is bound to `options`, but React on Rails reads props only from `options[:props]`, so the component renders with no props instead of failing loudly. This is the more dangerous case: un-migrated views do not error; they just lose their data.

### Detecting the collision quickly

Before adding the gem, audit existing positional-style calls so you know what needs a shim or a same-PR migration. Pay particular attention to two-argument calls, which fail silently rather than raising:

```bash
rg -n "react_component\\b" app/views app/components app/mailers app/helpers
# or without ripgrep:
grep -rEn "react_component\\b" app/views app/components app/mailers app/helpers
```

`app/helpers` catches view-helper wrappers that call `react_component` from Ruby rather than a template. Expand the path list further if you mount React from other locations (Phlex views, gem engines, etc.), or drop the path argument entirely to search the whole project and filter out false positives manually.

Any call that passes props as the second positional argument (rather than `{ props: ... }`) will break as soon as `react_on_rails` is loaded — either by raising `ArgumentError` (3+ args) or by silently dropping props (2 args).

### Option A: migrate all call sites in the same PR (recommended)

The cleanest path is to update every `react_component` call to the options-hash form in the same PR that adds the gem. See the syntax change under [Legacy compatibility fixes](#legacy-compatibility-fixes-that-often-make-migration-one-shot). After this, there is no collision to manage — the new helper is the only helper.

### Option B: preserve the legacy helper and use an explicit alias

If a single-PR migration is impractical, you can keep `react-rails`'s `react_component` semantics for un-migrated views and introduce a separate helper name for migrated mounts.

Define the shim module directly in an initializer so it lives outside Zeitwerk's autoload paths. The module:

1. Prepends an override so legacy `react_component(...)` calls keep delegating to `React::Rails::ViewHelper`.
2. Exposes an explicit `react_on_rails_component(...)` alias for migrated mounts.

> **Note:** this initializer was contributed by a community member migrating a production app. It is not covered by the `react_on_rails` test suite. Verify it works in a staging environment before relying on it in production.

```ruby
# config/initializers/react_on_rails_coexistence.rb
module ReactOnRailsCoexistence
  # Legacy react-rails semantics for un-migrated views.
  # Delegates to React::Rails::ViewHelper#react_component. Accepts and
  # forwards a block, which react-rails uses for mount-tag content.
  module LegacyReactComponent
    def react_component(name, props = {}, options = {}, &block)
      # Standard Rails views have the react-rails helper support methods.
      # Engines, ViewComponent, mailers, and other restricted contexts may not.
      # See Known Limitations below.
      React::Rails::ViewHelper.instance_method(:react_component)
                              .bind_call(self, name, props, options, &block)
    end
  end

  # Explicit alias for migrated mounts.
  # Uses the React on Rails options-hash shape: (name, options = {}).
  # Fetches from ReactOnRails::Helper directly (not ReactOnRailsHelper) so
  # migrated mounts always call the React on Rails implementation rather than
  # the prepended LegacyReactComponent override.
  def react_on_rails_component(name, options = {})
    ReactOnRails::Helper.instance_method(:react_component)
                        .bind_call(self, name, options)
  end
end

Rails.application.config.to_prepare do
  # Safe to re-run on every reload: Ruby skips the insertion when the module
  # is already in the ancestor chain, so duplicates never accumulate.
  ReactOnRailsHelper.prepend(ReactOnRailsCoexistence::LegacyReactComponent)
  ActionView::Base.include(ReactOnRailsCoexistence)
end
```

Defining the module inline in the initializer avoids a subtle issue: files under `app/helpers/` are on Zeitwerk's autoload paths, and `require`-ing such a file from an initializer can confuse Zeitwerk's bookkeeping in production eager-load mode. Keeping the module in `config/initializers/` sidesteps that entirely.

Use `react_on_rails_component(...)` in new or migrated views:

```erb
<%= react_on_rails_component("CommandBar", props: { title: "Hi" }, prerender: true) %>
```

Leave existing `react_component(...)` calls untouched until you are ready to migrate them. When every call site has been converted, update each migrated call site from `react_on_rails_component(...)` back to `react_component(...)` and delete `config/initializers/react_on_rails_coexistence.rb`. A project-wide find-and-replace over `react_on_rails_component` makes the final pass quick. See [Known limitations of Option B](#known-limitations-of-option-b) below for the full cost of this approach.

### Known limitations of Option B

- **Two project-wide renames.** Every migrated call site is renamed twice: `react_component` → `react_on_rails_component` while the shim is active, then `react_on_rails_component` → `react_component` once the shim is removed. On a large app this can equal or exceed the effort of migrating call sites in a single PR (Option A). Factor this in before choosing Option B.
- This is a migration-only pattern. Carry the shim only as long as legacy calls remain, then remove it.
- Edits to `config/initializers/react_on_rails_coexistence.rb` require a server restart in development, like any initializer.
- **The shim is app-level and can hard-fail in restricted view contexts.** In gem-provided engines, Rails engines, ViewComponent, or Action Mailer views, the receiver may be missing helper methods used by `react-rails` or React on Rails. That means legacy `react_component(...)` calls and migrated `react_on_rails_component(...)` calls can both fail at render time even though the method name is visible. Explicitly include the needed helper module or add a context-local wrapper before using either helper in those contexts.
- **Remove the initializer before (or at the same time as) removing `react-rails` from the `Gemfile`.** The shim's method body references `React::Rails::ViewHelper`, so once the gem is gone any request that still routes through the legacy delegate raises `NameError: uninitialized constant React::Rails::ViewHelper` at render time. Delete `config/initializers/react_on_rails_coexistence.rb` in the same commit that drops the gem.
- Server rendering, Pro features, and auto-bundling all work through the explicit `react_on_rails_component` alias — the shim only forwards the default helper name back to `react-rails`.

## Practical checklist for Webpacker-era apps

See [Preferred path for Webpacker-era apps](#preferred-path-for-webpacker-era-apps) above for the recommended staging. The concrete checklist follows.

If your app looks like this:

- `gem "webpacker"` in `Gemfile`
- `react_ujs` in `package.json`
- `app/javascript/packs/application.js`
- `app/javascript/packs/server_rendering.js`

then treat the migration as:

1. Move from `webpacker` to `shakapacker` in its own PR.
2. If the app is still on Rails 5.1, upgrade Rails to 5.2+ before adding current `react_on_rails`.
3. Remove `react_ujs`.
4. Run the React on Rails install generator.
5. Replace helper syntax and component registration.
6. Review `bin/dev`, `config/shakapacker.yml`, and webpack config diffs before committing.

Current React on Rails does not support `gem "webpacker"`. The install generator adds Shakapacker rather than enforcing a hard install-time block, and `react_on_rails doctor` flags Webpacker as a removed/breaking-change issue when it detects `config/webpacker.yml` or `bin/webpacker`. Migrate to Shakapacker first (step 1 above) rather than budgeting time for Webpacker compatibility shims.
