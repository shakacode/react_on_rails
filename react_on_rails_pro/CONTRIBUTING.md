# Tips for Contributors

## Installation

Install [yalc](https://github.com/wclr/yalc).


```sh
cd react_on_rails_pro
bundle && yarn && cd spec/dummy && bundle && yarn
```
To use the `React 18 Apollo with GraphQL` example you need to seed the testing database inside `spec/dummy` directory.
```sh
rake db:seed
```


See the example apps under `/spec`

## Summary

For non-doc fixes:

* Provide changelog entry in the [unreleased section of the CHANGELOG.md](https://github.com/shakacode/react_on_rails_pro/blob/master/CHANGELOG.md#unreleased).
* Ensure CI passes and that you added a test that passes with the fix and fails without the fix.
* Squash all commits down to one with a nice commit message *ONLY* once final review is given. Make sure this single commit is rebased on top of master.
* Please address all code review comments.
* Ensure that docs are updated accordingly if a feature is added.

## Commit Messages

From [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/)

#### The seven rules of a great git commit message
> Keep in mind: This has all been said before.

1. Separate subject from body with a blank line
1. Limit the subject line to 50 characters
1. Capitalize the subject line
1. Do not end the subject line with a period
1. Use the imperative mood in the subject line
1. Wrap the body at 72 characters
1. Use the body to explain what and why vs. how


## Doc Changes

When making doc changes, we want the change to work on both https://www.shakacode.com/react-on-rails-pro/docs/ and when browsing the GitHub repo. 
The issue is that the Shakacode site is generated only from files in [`docs`](./docs), so any references from them to non-doc files must use the full GitHub URL.

### Links to other docs:
* When making references to doc files, use a relative URL path like:
`[Installation Overview](docs/basics/installation-overview.md)`

* When making references to source code files, use a full url path like:
`[spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails_pro/tree/master/spec/dummy/config/initializers/react_on_rails.rb)`


## To run tests:
See [Run NPM JS tests](#run-npm-js-tests) for the JS tests and [RSpec Testing](#rspec-testing) for the Ruby tests.

See [Dev Initial Setup](#dev-initial-setup) below for, well... initial setup.


# IDE/Editor Setup
It's critical to configure your IDE/editor to ignore certain directories. Otherwise your IDE might slow to a crawl!

* /coverage
* /tmp
* /node_modules
* /spec/dummy/app/assets/webpack
* /spec/dummy/log
* /spec/dummy/node_modules
* /spec/dummy/client/node_modules
* /spec/dummy/tmp


# Configuring your test app to use your local fork
You can test the `react_on_rails_pro` gem using your own external test_app or the gem's internal `spec/dummy` app. The `spec/dummy` app is an example of the various setup techniques you can use with the gem.
As of 2018-04-28, this directory mirrors the test app spec/dummy on https://github.com/shakacode/react_on_rails plus a few additional tests.

```
├── test_app
|    └── client
└── react_on_rails_pro
    └── spec
        └── dummy
```

## Testing the Ruby Gem
If you want to test the ruby parts of the gem with an application before you release a new version of the gem, you can specify the path to your local version via your test app's Gemfile:

```ruby
gem "react_on_rails_pro", path: "../path-to-react_on_rails_pro"
gem "react_on_rails"
```
================================================================================

Set `config.server_renderer = "NodeRenderer"` in your  `ReactOnRailsPro.configure` block in the initializer.

After making this change, run `bundle install`.

> [!NOTE]
> You will need to restart your Rails application if you make any changes to the gem.

## Testing the Node package for react_on_rails_pro
In addition to testing the Ruby parts out, you can also test the node package parts of the gem with an external application.

To do this, follow the instructions in the
[Local Node Package](#local-node-package).

### Example: Testing NPM changes with the dummy app

1. Add `console.log('Hello!')` [here](https://github.com/shakacode/react_on_rails_pro/blob/more_test_and_docs/packages/node-renderer/src/ReactOnRailsProNodeRenderer.js#L6) in `packages/node-renderer/src/ReactOnRailsProNodeRenderer.js` to confirm we're getting an update to the node package.
2. The `preinstall` script of `spec/dummy` builds the NPM package and sets up `yalc` to use it for the renderer. 
   It's run automatically when you run `yarn install`. 
3. Refresh the browser if the server is already running or start the server using `foreman start -f Procfile.dev` from `spec/dummy` and navigate to `http://localhost:3000/`. You will now see the `Hello!` message printed in the browser's console.

> [!NOTE]
> `yalc` makes the NPM package available globally on the machine.
> So, if you have the repo checked out more than once to compare behavior between branches,
> make sure to run `yarn install` every time you switch to a new copy.

# Development Setup for Gem and Node Package Contributors

## Checklist before Committing
1. Run all JS tests, dummy app tests and linters.
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?

## Dev Initial Setup

### Prereqs
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), cd to `spec/dummy` and run `bin/setup` to install ruby dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


### Building the Node Package for Development

At the root:
```
nps build
```

### Modifying the startup for testing

This is a possible update to package.json to debug the lockfile. Notice the `NODE_DEBUG=LOCKFILE,ROR`

```json
    "developing": "rm -rf /tmp/react-on-rails-pro-node-renderer-bundles && RENDERER_LOG_LEVEL=info NODE_DEBUG=LOCKFILE,ROR node --enable-source-maps --experimental-modules packages/node-renderer/lib/default-node-renderer.js",
```

See https://nodejs.org/api/util.html#util_util_debuglog_section for details on `debuglog`.

### Local Node Package
Because the example and dummy apps rely on the `react_on_rails_pro` node package, they should link directly to your local version to pick up any changes you may have made to that package.
To achieve this, you can use `yalc`.
The easy way to do this is to run the command below in the dummy app root directory.
For more information check the script section of the
[spec/dummy/package.json](spec/dummy/package.json) file.

```sh
cd spec/dummy
yarn install
```

> [!NOTE]
> This runs npm under the hood as explained in the **Test NPM for react_on_rails_pro** section above.

From now on, the example and dummy apps will use your local packages/node-renderer folder as the `react_on_rails_pro` node package.

### Install NPM dependencies and build the NPM package for react_on_rails_pro

```sh
cd react_on_rails_pro
yarn install
```

Or run this, which builds the yarn package, then the webpack files for spec/dummy, and finally runs tests in
spec/dummy.


```sh
# Optionally change default selenium_firefox driver
# export DRIVER=poltergeist
cd react_on_rails_pro
yarn run dummy:spec
```

### Run NPM JS tests

```sh
cd react_on_rails_pro
yarn test
```

### Debugging NPM JS tests

Example of using ndb to debug a test
```bash
ndb $(yarn bin)/jest --runInBand  packages/node-renderer/tests/**/*.test.[jt]s -t 'FriendsAndGuests bundle for commit 1a7fe417'
```
Hit F8 and then a debugger statement within the test will get hit.

### Creating new VM tests
1. copy a server bundle to `packages/node-renderer/tests/fixtures/projects/<project-name>/<commit>`
2. create a directory with a hash representing the commit of the project

### Async issues with Jest
Beware that Jest runs multiple test files synchronously, so you can't use the same temporary directory
between tests. See the file [`packages/node-renderer/tests/helper.ts`](packages/node-renderer/tests/helper.ts) for how we handle this.

### Run most tests and linting

```sh
cd react_on_rails_pro
yarn run check
```

### Starting the Dummy App
Before running the dummy app,
you need to generate JavaScript packs in the dummy app project.
To do this,
go to `spec/dummy` directory and run the following rake task:

```sh
bundle exec rake react_on_rails:generate_packs
```

Since the dummy app requires several processes to run in the background, don't run `rails s` directly.
Instead, run `foreman start -f Procfile.dev`.
This requires [the `foreman` gem](https://github.com/ddollar/foreman) to be installed (`gem install foreman`).
Alternatively, you can use [`overmind`](https://github.com/DarthSim/overmind).

Doing this ensures the asset generation by webpack
and node renderer run in the background,
which is essential for the dummy app to work.

If you change the webpack configs, then you need to restart `foreman`.

### RSpec Testing

Before running Ruby tests ensure you have done the following steps in `spec/dummy` directory:

```sh
# in the root directory
bundle install
yarn install

cd spec/dummy

bundle install
bundle exec rake react_on_rails:generate_packs

yarn install

RAILS_ENV=test bin/shakapacker # to generate assets for test environment
```

Then in a separate terminal, run the following to run the Node renderer and the test Rails server (only needed for the streaming tests) in the background:

```sh
# in spec/dummy directory
yarn run node-renderer
RAILS_ENV=test bin/dev&
```

Get back to your main terminal and run:

```sh
bundle exec rspec
```

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

After running a test, you can view the coverage results in SimpleCov reports by opening `coverage/index.html`.

### Debugging
Start the sample app like this for some debug printing:

```sh
TRACE_REACT_ON_RAILS=true && foreman start -f Procfile.dev
```

# Releasing

⚠️ **The release process has moved to the repository root.**

React on Rails Pro is now released together with React on Rails using unified versioning.
All packages (core + pro) are released together with the same version number.

Contact Justin Gordon, [justin@shakacode.com](mailto:justin@shakacode.com) for release permissions.

## Prerequisites

You need authentication for both public and private package registries:

**Public packages (npmjs.org + rubygems.org):**
- NPM: Run `npm login`
- RubyGems: Standard credentials via `gem push`

**Private packages (GitHub Packages):**
- Get a GitHub personal access token with `write:packages` scope
- Configure `~/.npmrc`:
  ```ini
  //npm.pkg.github.com/:_authToken=<TOKEN>
  always-auth=true
  ```
- Configure `~/.gem/credentials`:
  ```yaml
  :github: Bearer <GITHUB_TOKEN>
  ```
- Set environment variable: `export GITHUB_TOKEN=<TOKEN>`

## Release Command

From the **repository root**, run:

```bash
# Full release
cd /path/to/react_on_rails
rake release[17.0.0]

# Dry run first
rake release[17.0.0,true]

# Test with Verdaccio
rake release[17.0.0,false,verdaccio]
```

For complete documentation, see:
- [Root Release Documentation](../docs/contributor-info/releasing.md)
- Run `rake -D release` for inline help
