# Getting Started with an existing Rails app

**Also consult the instructions for installing on a fresh Rails app**, see the [React on Rails Basic Tutorial](../getting-started/tutorial.md).

**If you have Rails 5 API only project**, first [convert the Rails 5 API only app to a normal Rails app](../migrating/convert-rails-5-api-only-app.md).

1. Add the following to your Gemfile and run `bundle install`.
   We recommend fixing exact versions, as the gem and npm package versions should stay in sync.
   For pre-release versions, gems use periods (for example, `16.4.0.rc.5`) and npm packages use dashes
   (for example, `16.4.0-rc.5`).

   ```ruby
   gem "shakapacker", "<shakapacker_version>"
   gem "react_on_rails", "<react_on_rails_gem_version>"
   ```

   Or use `bundle add`:

   ```bash
   bundle add shakapacker --version="<shakapacker_version>" --strict
   bundle add react_on_rails --version="<react_on_rails_gem_version>" --strict
   ```

   Then install the matching npm packages (versions must stay in sync with the gems):

   ```bash
   # Use your preferred package manager
   yarn add react-on-rails@<react_on_rails_npm_version> shakapacker@<shakapacker_version> --exact
   # or: npm install react-on-rails@<react_on_rails_npm_version> shakapacker@<shakapacker_version> --save-exact
   ```

2. Run the following command to install Shakapacker with React. Note, if you are using an older version of
   Rails than 5.1, you'll need to install Webpacker with React per the
   [Webpacker React installation guide](https://github.com/rails/webpacker).

   ```bash
   bundle exec rails shakapacker:install
   ```

3. Commit this to git (or else you cannot run the generator unless you pass the option `--ignore-warnings`).

4. Run the generator with a simple "Hello World" example (more options below):

   ```bash
   bundle exec rails generate react_on_rails:install
   ```

   For more information about this generator use `--help` option:

   ```bash
   bundle exec rails generate react_on_rails:install --help
   ```

5. Ensure that you have `overmind` or `foreman` installed.

   Note: `foreman` should be installed on the system not on your project. [Read more](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman)

6. Start your Rails server:

   ```bash
   ./bin/dev
   ```

   If port 3000 is already in use, set an explicit port:

   ```bash
   PORT=3001 ./bin/dev
   ```

7. Visit the app on the port you used (default: [localhost:3000/hello_world](http://localhost:3000/hello_world)).

## Installation

## NPM

All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command (assuming you are in the directory where you have your `node_modules`):

```bash
# Use your preferred package manager
npm install react-on-rails --save-exact
# or: yarn add react-on-rails --exact
# or: pnpm add react-on-rails --save-exact
```

That will install the latest version and update your package.json.
**NOTE:** the `--save-exact` (or `--exact` for yarn) flag will ensure that you do not have a "~" or "^" for your react-on-rails version in your package.json.

## What's Next?

Now that you have React on Rails running, here are ways to level up:

- **Add server-side rendering** — [SSR guide](../core-concepts/react-server-rendering.md)
- **See the feature comparison** — [OSS vs Pro](./oss-vs-pro.md)
- **Upgrade to Pro** for React Server Components, streaming SSR, and 10-100x faster SSR — [3-step upgrade guide](../../pro/upgrading-to-pro.md)
- **Explore the full docs** — [Documentation index](../../README.md)
