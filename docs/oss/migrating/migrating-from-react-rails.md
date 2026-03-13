## Migrate From react-rails

In this guide, it is assumed that you have upgraded the `react-rails` project to use `shakapacker` version 7. To this end, check out [Shakapacker v7 upgrade guide](https://github.com/shakacode/shakapacker/tree/master/docs/v7_upgrade.md). Upgrading `react-rails` to version 3 can make the migration smoother but it is not required.

If `package.json` is missing `packageManager`, set it to your project's actual manager and exact version before running install generators:

```bash
# pick the one that matches your lockfile
npm pkg set packageManager='npm@10.9.2'
npm pkg set packageManager='yarn@1.22.22'
npm pkg set packageManager='pnpm@10.12.1'
npm pkg set packageManager='bun@1.2.13'
```

1. Update Deps
   1. Replace `react-rails` in `Gemfile` with the latest version of `react_on_rails` and run `bundle install`.
   2. Remove `react_ujs` from `package.json` and run your package manager's install command (e.g., `pnpm install`, `yarn install`, or `npm install`).
   3. Commit changes!

2. Run `rails g react_on_rails:install` but do not commit the change. `react_on_rails` attempts to install node dependencies, creates a sample React component, Rails view/controller, and updates `config/routes.rb`. If dependency installation fails, the generator prints manual install commands. If required package-manager tooling (Node.js and npm/yarn/pnpm/bun) is unavailable, the generator stops with setup guidance. Run the suggested commands or install missing tools before continuing.

3. Adapt the project: Check the changes and carefully accept, reject, or modify them as per your project's needs. Besides changes in `config/shakapacker` or `babel.config` which are project-specific, here are the most noticeable changes to address:
   1. Check Webpack config files at `config/webpack/*`. If coming from `react-rails` v3, the changes are minor since you have already made separate configurations for client and server bundles. The most important change here is to notice the different names for the server bundle entry file. You may choose to stick with `server_rendering.js` or use `server-bundle.js` which is the default name in `react_on_rails`. The decision made here affects the other steps.

   2. In `app/javascript` directory you may notice some changes.
      1. `react_on_rails` by default uses `bundles` directory for the React components. You may choose to rename `components` into `bundles` to follow the convention.

      2. `react_on_rails` uses `client-bundle.js` and `server-bundle.js` instead of `application.js` and `server_rendering.js`. There is nothing special about these names. It can be set to use any other name (as mentioned above). If you too choose to follow the new names, consider updating the relevant `javascript_pack_tag` in your Rails views.

      3. Update the content of these files to register your React components for client or server-side rendering. Checking the generated files by `react_on_rails` installation process should give enough hints.

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

You can also check [react-rails-to-react-on-rails](https://github.com/shakacode/react-rails-example-app/tree/react-rails-to-react-on-rails) branch on [react-rails example app](https://github.com/shakacode/react-rails-example-app) for an example of migration from `react-rails` v3 to `react_on_rails` v13.4.
