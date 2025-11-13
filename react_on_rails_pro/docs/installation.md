# Installation

Since the repository is private, you will get a **GitHub Personal Access Token** and an account that can access the packages. Substitute that value in the commands below. If you dont' have this, ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.

Check the [CHANGELOG](https://github.com/shakacode/react_on_rails_pro/blob/master/CHANGELOG.md) to see what version you want.

# Version

For the below docs, find the desired `<version>` in the CHANGELOG. Note, for pre-release versions, gems have all periods, and node packages uses a dash, like gem `3.0.0.rc.0` and node package `3.0.0-rc.0`.

# Ruby

## Gem Installation

1. Ensure your **Rails** app is using the **react_on_rails** gem, version greater than 11.0.7.
1. Add the `react_on_rails_pro` gem to your **Gemfile**. Substitute the appropriate version number.

## Gemfile Change

Replace the following in the snippet for the Gemfile

1. `<account>` for the api key
2. `<api-key>`
3. `<version>` desired

```ruby
source "https://<rorp-account>:<token>@"\
  "rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "<version>"
end
```

## Alternate installation keeping the key out of your Gemfile

```ruby
source "https://rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "<version>"
end
```

Or use the `gem install` command:

```bash
gem install react_on_rails_pro --version "<version>> --source "https://rubygems.pkg.github.com/shakacode-tools"
```

Then edit your permissions for bundler at the command line:

```
bundle config set rubygems.pkg.github.com <username>:<token>
```

## Using a branch in your Gemfile

Note, you should probably use an ENV value for the token so that you don't check this into your source code.

```ruby
gem "react_on_rails_pro", version: "<version>", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git", tag: "<version>"
```

## Rails Configuration

You don't need to create an initializer if you are satisfied with the default as described in
[Configuration](./configuration.md)

# Node Package

Note, you only need to install the Node Package if you are using the standalone node renderer, `NodeRenderer`.

## Installation

1. Create a subdirectory of your rails project for the Node renderer. Let's use `react-on-rails-pro`.
2. Create a file `react-on-rails-pro/.npmrc` with the following

```
always-auth=true
//npm.pkg.github.com/:_authToken=<token>
@shakacode-tools:registry=https://npm.pkg.github.com
```

3. Create a `react-on-rails-pro/package.json`

```json
{
  "private": true,
  "dependencies": {
    "@shakacode-tools/react-on-rails-pro-node-renderer": "<version>"
  },
  "scripts": {
    "node-renderer": "echo 'Starting React on Rails Pro Node Renderer.' && node ./react-on-rails-pro-node-renderer.js"
  }
}
```

4. Be sure to run `npm i` **and not** `yarn` as only npm seems to work with the private github packages.

If you really want to use yarn, see [Yarn can't find private Github npm registry](https://stackoverflow.com/questions/58316109/yarn-cant-find-private-github-npm-registry)

5. You can start the renderer with either the executable `node-renderer` or, preferably, with
   a startup JS file, say called `react-on-rails-pro/react-on-rails-pro-node-renderer.js` with
   these contents. \_Note the use of the namespaced **`@shakacode-tools/react-on-rails-pro-node-renderer`** for the package.

```js
const path = require('path');
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');

const env = process.env;

const config = {
  serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),

  // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'debug', // show all logs

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env
  // value in real app.
  password: 'myPassword1',

  // Save bundle to "tmp/bundles" dir of our dummy app
  // This is the default
  port: env.RENDERER_PORT || 3800,

  // supportModules should be set to true to allow the server-bundle code to
  // see require, exports, etc.
  // `false` is like the ExecJS behavior
  // this option is required to equal `true` in order to use loadable components
  supportModules: true,

  // workersCount defaults to the number of CPUs minus 1
  workersCount: Number(process.env.NODE_RENDERER_CONCURRENCY || 3),

  // Next 2 params, allWorkersRestartInterval and
  // delayBetweenIndividualWorkerRestarts must both should be set if you wish
  // to have automatic worker restarting, say to clear memory leaks.
  // time is in minutes between restarting all workers
  // Enable next 2 if the renderer is running out of memory
  // allWorkersRestartInterval: 15,
  // time in minutes between each worker restarting when restarting all workers
  // delayBetweenIndividualWorkerRestarts: 2,
  // Also, you can set he parameter gracefulWorkerRestartTimeout to force the worker to restart
  // If it's the time for the worker to restart, the worker waits until it serves all active requests before restarting
  // If a worker stuck because of a memory leakage or an infinite loop, you can set a timeout that master waits for it before killing the worker
};

// Renderer detects a total number of CPUs on virtual hostings like Heroku
// or CircleCI instead of CPUs number allocated for current container. This
// results in spawning many workers while only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
```

## Instructions for using a branch

Install the node-renderer executable, possibly globally. Substitute the branch name or tag for `master`

```
yarn global add https://<your-github-token>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
```

This installs a binary `node-renderer`.

### Using Github packages

Login into npm

```bash
npm install @shakacode-tools/react-on-rails-pro-node-renderer@<version>
```

or edit package.json directly

```json
"@shakacode-tools/react-on-rails-pro-node-renderer": "<version>"
```

### Configuration

See [NodeRenderer JavaScript Configuration](./node-renderer/js-configuration.md).

#### Webpack Configuration

Set your server bundle webpack configuration to use a target of `node` per the [Webpack docs](https://webpack.js.org/concepts/targets/#usage).

## Authentication when using Github packages

[Auth for the npm package](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-npm-for-use-with-github-packages#authenticating-to-github-packages)

Create a new ~/.npmrc file if one doesn't exist.

```
//npm.pkg.github.com/:_authToken=TOKEN
```

To configure bundler if you don't want the token in your Gemfile:

```
bundle config https://rubygems.pkg.github.com/OWNER USERNAME:TOKEN
```
