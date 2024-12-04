# Tips for Contributors

## Installation

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

When making doc changes, we want the change to work on both the gitbook and the regular github site. The issue is that non-doc files will not go to the gitbook site, so doc references to non doc files must use the github URL.

### Links to other docs:
* When making references to doc files, use a relative URL path like:
`[Installation Overview](docs/basics/installation-overview.md)`

* When making references to source code files, use a full url path like:
`[spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb)`


## To run tests:
* After updating code via git, to run all **JS** tests for Node package:
```sh
cd react_on_rails_pro
yarn run test
```

* To run **RSpec** tests on dummy app, first launch renderer server:
```sh
  cd react_on_rails_pro/spec/dummy
  yarn run node-renderer
```
and then run **RSpec** in another console  window/tab:
```sh
  cd react_on_rails_pro/spec/dummy
  rspec
```

See Dev Initial Setup, below for, well... initial setup.

# IDE/IDE SETUP
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

Set `config.server_renderer = "NodeRenderer"` in your  `ReactOnRailsPro.configure` block.

Note that you will need to bundle install after making this change, but also that **you will need to restart your Rails application if you make any changes to the gem**.

## Testing the Node package for react_on_rails_pro
In addition to testing the Ruby parts out, you can also test the node package parts of the gem with an external application.

To do this, follow the instructions in the
[Local Node Package](#local-node-package).

#### Example: Testing NPM changes with the dummy app

1. Add `console.log('Hello!')` [here](https://github.com/shakacode/react_on_rails_pro/blob/more_test_and_docs/packages/node-renderer/src/ReactOnRailsProNodeRenderer.js#L6) in `react_on_rails/packages/node-renderer/src/ReactOnRailsProNodeRenderer.js` to confirm we're getting an update to the node package.
2. The `preinstall` script of `spec/dummy` sets up `yalc` to use `react-on-rails-pro` for the renderer.
3. Refresh the browser if the server is already running or start the server using `foreman start -f Procfile.dev` from `react_on_rails/spec/dummy` and navigate to `http://localhost:3000/`. You will now see the `Hello!` message printed in the browser's console.

_Note: you don't have to build the NPM package since it is used only with node runtime and its source code is exactly what is executed when you run it._

# Development Setup for Gem and Node Package Contributors

## Checklist before Committing
1. Run all JS tests, dummy app tests and linters.
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?

## Dev Initial Setup

### Prereqs
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), cd to `spec/dummy` and run `bin/setup` to install ruby dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


### Building the Node Package for Development

```
yarn run build:dev
```

### Modifying the startup for testing


This is a possible update to package.json to debug the lockfile. Notice the `NODE_DEBUG=LOCKFILE`

```json
    "developing": "rm -rf /tmp/react-on-rails-pro-node-renderer-bundles && RENDERER_LOG_LEVEL=info NODE_DEBUG=LOCKFILE,ROR node --enable-source-maps --experimental-modules packages/node-renderer/lib/default-node-renderer.js",
```

Notice the 2 "debug" settings of LOCKFILE and ROR.

See https://nodejs.org/api/util.html#util_util_debuglog_section for details on `debuglog`.

### Local Node Package
Because the example and dummy apps rely on the `react_on_rails_pro` node package, they should link directly to your local version to pick up any changes you may have made to that package.
To achieve this, you can use `yalc`.
The easy way to do this is to run the command below in the dummy app root directory.
For more information check the script section of the
[package.json](spec/dummy/package.json)
in `spec/dummy` app directory.

```sh
cd spec/dummy
yarn run preinstall
```

_Note: this runs npm under the hood as explained in **Test NPM for react_on_rails_pro** section above_

From now on, the example and dummy apps will use your local packages/node-renderer folder as the `react_on_rails_pro` node package.

### Install NPM dependencies and build the NPM package for react_on_rails_pro

```sh
cd react_on_rails_pro
yarn install
```

Or run this which builds the yarn package, then the webpack files for spec/dummy, and runs tests in
spec/dummy.


```sh
# Optionally change default selenium_firefox driver
export DRIVER=poltergeist
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

### Asynch issues with Jest
Beware that Jest runs multiple test files synchronously, so you can't use the same tmp directory
between tests. See the file `packages/node-renderer/tests/helper.js` for how this was handled.

### Run spec/dummy tests

TODO: Figure out how to run the tests on CI.

```sh
cd react_on_rails_pro/spec/dummy
yarn run node-renderer
```
and in another console window/tab:

```sh
cd react_on_rails_pro/spec/dummy
rspec
```

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

Since the dummy app requires several process to run in the background, don't run `rails s` directly.
Instead, run `foreman start -f Procfile.dev`.
This requires `foreman` gem to be already installed (`gem install foreman`).
Alternatively, you can use `overmind`.

Doing this, ensures the asset generation by webpack
and node renderer run in the background,
which is essential for the dummy app to work.

If you change the webpack configs, then you need to restart `foreman`.

### RSpec Testing

Before running ruby tests ensure you have done the following steps in `spec/dummy` directory:

```sh
# in the root directory
bundle install
yarn install

cd spec/dummy

bundle exec rake react_on_rails:generate_packs

yarn run preinstall
yarn install

RAILS_ENV=test bin/shakapacker # to generate assets for test environment
```

Then in a separate terminal, run the following to get node rendered run in background:

```sh
# in spec/dummy directory
yarn run node-renderer
```

Get back to your main terminal and run:

```sh
bundle exec rspec`
```

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

After running a test, you can view the coverage results in SimpleCov reports by opening `coverage/index.html`.

### Debugging
Start the sample app like this for some debug printing:

```sh
TRACE_REACT_ON_RAILS=true && foreman start -f Procfile.dev
```

# Releasing
Contact Justin Gordon, justin@shakacode.com

Notes, these 2 files need auth tokens to [publish to Github Packages](https://docs.github.com/en/enterprise-server%403.10/packages/working-with-a-github-packages-registry/working-with-the-rubygems-registry):
1. `~/.npmrc`
2. `~/.gem/credentials`

Then run a command like:
```bash
bundle exec rake release\[4.0.0.rc.1\]
```
