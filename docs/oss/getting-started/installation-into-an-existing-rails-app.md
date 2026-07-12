---
slug: existing-rails-app
---

# Install into an Existing Rails App

Use this path when you already have a Rails application and want React on Rails to generate the missing integration files for you.

> [!NOTE]
> **Summary for AI agents:** Use this page when the user has an existing Rails app and wants to add React. For new apps, use [Quick Start](./quick-start.md). If the app still uses Webpacker, expect a two-step migration (Webpacker → Shakapacker → React on Rails). Rails 7+ is recommended.

## Preflight

- Rails 7+ is recommended. Rails 5.2+ can work, but Webpacker-era apps usually need an incremental upgrade first.
- If your app still uses `webpacker`, expect this to be a two-step migration: move to `shakapacker`, then install React on Rails.
- If your app is Rails 5 API-only, first [convert it to a standard Rails app](../migrating/convert-rails-5-api-only-app.md).
- Commit or stash your current work if you want the generated diff to be easier to review. The generator updates files like `bin/dev`, `config/shakapacker.yml`, routes, initializers, and sample views/controllers.

## 1. Add the gems

```bash
bundle add shakapacker --strict
bundle add react_on_rails --strict
```

React on Rails attempts to install the matching `react-on-rails` JavaScript package during the generator run. In some existing apps, dependency installation can fail (or required package-manager tooling may be unavailable), and the generator prints manual install commands. Run those commands before starting the app.

### Optional: pin exact gem and npm versions yourself

If you manage versions manually, keep the Ruby gem and npm package on the same release. Pre-release gems use dots while npm uses hyphens. Replace `VERSION` below with the latest version from [the CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md).

```ruby
gem "react_on_rails", "VERSION"
```

```bash
npm install react-on-rails@VERSION --save-exact
# or: yarn add react-on-rails@VERSION --exact
# or: pnpm add react-on-rails@VERSION --save-exact
# or: bun add react-on-rails@VERSION --exact
```

## 2. Run the generator

```bash
bundle exec rails generate react_on_rails:install --typescript
```

TypeScript is the recommended default for new integrations. If you want JavaScript instead, omit `--typescript`.

When you run the generator in an interactive terminal without choosing a product mode, it asks whether to enable
React on Rails Pro. Press Enter or answer `y` to include the Node Renderer and the Pro foundation for streaming SSR
and React Server Components. Pro is free for evaluation; production use requires a subscription. See the
[Pro upgrade guide](../../pro/upgrading-to-pro.md) for licensing and setup details.

The prompt never appears in CI, redirected-input scripts, or other noninteractive sessions; those runs preserve the
existing open-source-only default. Pass `--pro` or `--rsc` to select Pro without a prompt. Pass `--no-pro`,
`--no-rsc`, or `--standard-only` to select the open-source setup explicitly and suppress the prompt.
Because `--standard-only` is an explicit open-source choice, the generator rejects combining it with `--pro` or `--rsc`.

For generator options such as `--rspack`, `--pro`, or `--rsc`, see the [generator details](../api-reference/generator-details.md).

If the generator reports dependency-install warnings (for example, `JavaScript dependencies installation failed ...` followed by `Please run manually:`), run your package manager install and then compile once before starting the app:

```bash
# pick one package manager
npm install
# or: pnpm install
# or: yarn install
# or: bun install

bundle exec rails shakapacker:compile
```

If you are migrating from `react-rails`, also run the compatibility checklist in [Migrate from react-rails](../migrating/migrating-from-react-rails.md#legacy-compatibility-fixes-that-often-make-migration-one-shot).

## 3. Start the app

Ensure that you have `overmind` or `foreman` installed so `bin/dev` can run both Rails and the asset watcher.

```bash
bin/rails db:prepare
./bin/dev
```

If port 3000 is already in use, set an explicit port:

```bash
PORT=3001 ./bin/dev
```

Visit the app on the port you used. By default that is [http://localhost:3000/hello_world](http://localhost:3000/hello_world).

## What the generator changes

The install generator typically adds or updates:

- `config/initializers/react_on_rails.rb`
- `config/shakapacker.yml`
- `bin/dev`
- `app/javascript/packs/server-bundle.js`
- example `HelloWorld` component files
- a sample route, controller, and view

Review these changes before adapting them to your actual application structure.

## What's Next?

- **Learn the generated structure** — [Using React on Rails](./using-react-on-rails.md)
- **Enable server-side rendering** — [SSR guide](../core-concepts/react-server-rendering.md)
- **Compare OSS and Pro** — [OSS vs Pro](./oss-vs-pro.md)
- **Upgrade to Pro** — [3-step upgrade guide](../../pro/upgrading-to-pro.md)
