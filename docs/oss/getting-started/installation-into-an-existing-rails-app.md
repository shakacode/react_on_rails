# Install into an Existing Rails App

Use this path when you already have a Rails application and want React on Rails to generate the missing integration files for you.

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

React on Rails installs the matching `react-on-rails` JavaScript package during the generator run, so you do not need to pre-install it in `package.json` unless you want to pin everything manually ahead of time.

### Optional: pin exact gem and npm versions yourself

If you manage versions manually, keep the Ruby gem and npm package on the same release. Pre-release gems use dots while npm uses hyphens.

```ruby
gem "react_on_rails", "16.4.0.rc.10"
```

```bash
npm install react-on-rails@16.4.0-rc.10 --save-exact
# or: yarn add react-on-rails@16.4.0-rc.10 --exact
# or: pnpm add react-on-rails@16.4.0-rc.10 --save-exact
```

## 2. Run the generator

```bash
bundle exec rails generate react_on_rails:install --typescript
```

TypeScript is the recommended default for new integrations. If you want JavaScript instead, omit `--typescript`.

For generator options such as `--rspack`, `--pro`, or `--rsc`, see the [generator details](../api-reference/generator-details.md).

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
