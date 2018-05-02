# Tips for Contributors

* See [docs/contributor-info/Releasing](./docs/contributor-info/releasing.md) for instructions on releasing.
* See other docs in [docs/contributor-info](./docs/contributor-info)

## Summary

For non-doc fixes:

* Provide changelog entry in the [unreleased section of the CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#unreleased).
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
* After updating code via git, to prepare all examples and run all tests:

```sh
cd react_on_rails/
bundle && yarn && rake examples:gen_all && rake node_package && rake
```

In order to run tests in browser
```
yarn global add  browserify babelify tape-run faucet
browserify -t babelify node_package/tests/*.js | tape-run | faucet
```

See Dev Initial Setup, below for, well... initial setup.

# IDE/IDE SETUP
It's critical to configure your IDE/editor to ignore certain directories. Otherwise your IDE might slow to a crawl!

* /coverage
* /tmp
* /gen-examples
* /node_package/lib
* /node_modules
* /spec/dummy/app/assets/webpack
* /spec/dummy/log
* /spec/dummy/node_modules
* /spec/dummy/client/node_modules
* /spec/dummy/tmp
* /spec/react_on_rails/dummy-for-generators

# Configuring your test app to use your local fork
You can test the `react-on-rails` gem using your own external test app or the gem's internal `spec/dummy` app. The `spec/dummy` app is an example of the various setup techniques you can use with the gem.
```
├── test_app
|    └── client
└── react_on_rails
    └── spec
        └── dummy
```

## Testing the Ruby Gem
If you want to test the ruby parts of the gem with an application before you release a new version of the gem, you can specify the path to your local version via your test app's Gemfile:

```ruby
gem "react_on_rails", path: "../path-to-react-on-rails"
```

Note that you will need to bundle install after making this change, but also that **you will need to restart your Rails application if you make any changes to the gem**.

## Testing the Node package for react-on-rails
In addition to testing the Ruby parts out, you can also test the node package parts of the gem with an external application. First, be **sure** to build the NPM package:

```sh
cd react_on_rails/
yarn
yarn run build
yarn install-react-on-rails
```

Install the local package by using yarn link, like this:
```sh
cd spec/dummy
yarn
```

Note, yarn will run the `postinstall` script of `spec/dummy/client` which runs `yarn link` to setup a sym link to the parent package.

#### Example: Testing NPM changes with the dummy app
1. Add `console.log('Hello!')` [here](https://github.com/shakacode/react_on_rails/blob/master/node_package/src/clientStartup.js#L181) in `react_on_rails/node_package/src/clientStartup.js` to confirm we're getting an update to the node package.
2. Refresh the browser if the server is already running or start the server using `foreman start` from `react_on_rails/spec/dummy` and navigate to `http://localhost:5000/`. You will now see the `Hello!` message printed in the browser's console.

_Note: running `npm i` automatically builds the npm package before installing. However, when using yarn you will need to run `yarn run build` in the root directory before the install script. This will be updated when [yarn issue #2649](https://github.com/yarnpkg/yarn/issues/2649) (above) is resolved._

# Development Setup for Gem and Node Package Contributors

## Checklist before Committing
1. `rake`: runs all linters and specs (you need Docker setup, see below)
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?

## Dev Initial Setup

### Prereqs
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), cd to `spec/dummy` and run `bin/setup` to install ruby dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Additionally, our RSpec tests use the poltergeist web driver. You will need to install the phantomjs node module:

```sh
yarn global add phantomjs-prebuilt
```

Note this *must* be installed globally for the dummy test project rspec runner to see it properly.

### Local Node Package
Because the example and dummy apps rely on the react-on-rails node package, they should link directly to your local version to pick up any changes you may have made to that package. To achieve this, switch to the dummy app's root directory and run this command below which runs something like [this script](spec/dummy/package.json#L14)

```sh
cd react_on_rails/spec/dummy
yarn run install-react-on-rails
```
_Note: this runs npm under the hood as explained in **Test NPM for react-on-rails** section above_

From now on, the example and dummy apps will use your local node_package folder as the react-on-rails node package. This will also be done automatically for you via the `rake examples:gen_all` rake task.

*Side note: It's critical to use the alias section of the webpack config to avoid a double inclusion error. This has already been done for you in the example and dummy apps, but for reference:*

```js
  resolve: {
    alias: {
      react: path.resolve('./node_modules/react'),
      'react-dom': path.resolve('./node_modules/react-dom'),
    },
  },
```

### Install NPM dependencies and build the NPM package for react-on-rails

```sh
cd react_on_rails/
yarn
yarn build
```

Or run this which builds the yarn package, then the webpack files for spec/dummy, and runs tests in
spec/dummy.


```sh
# Optionally change default selenium_firefox driver
export DRIVER=poltergeist
cd react_on_rails/
yarn run dummy:spec
```

### Run NPM JS tests

```sh
cd react_on_rails/
yarn test
```

### Run spec/dummy tests

```sh
cd react_on_rails/spec/dummy
rspec
```

Eventually, we may have JS tests:

```sh
cd react_on_rails/spec/dummy/client
yarn run test
```

### Run most tests and linting

```sh
cd react_on_rails/
yarn run check
```

### Starting the Dummy App
To run the dummy app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start`. If you don't do this, then `webpack` will not generate a new bundle, and you will be seriously confused when you change JavaScript and the app does not change. If you change the webpack configs, then you need to restart foreman. If you change the JS code for react-on-rails, you need to run `yarn run build`. Since the react-on-rails package should be sym linked, you don't have to `yarn react-on-rails` after every change.

### RSpec Testing
Run `rake` for testing the gem and `spec/dummy`. Otherwise, the `rspec` command only works for testing within the sample apps, like `spec/dummy`.

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

After running a test, you can view the coverage results SimpleCov reports by opening `coverage/index.html`.

Turbolinks 5 is included in the test app, unless "DISABLE_TURBOLINKS" is set to YES in the environment.

Run `rake -T` or `rake -D` to see testing options.

`rake all_but_examples` is typically best for developers, except if any generators changed.

See below for verifying changes to the generators.

### Install Generator
In your Rails app add this gem with a path to your fork.

```ruby
gem 'react_on_rails', path: '../relative/path/to/react_on_rails'
```

The main installer can be run with ```rails generate react_on_rails:install```

### Testing the Generator
The generators are covered by generator tests using Rails's generator testing helpers, but it never hurts to do a sanity check and explore the API. See [generator_testing_script.md](generator_testing_script.md) for a script on how to run the generator on a fresh project.

`rake run_rspec:example_basic` is a great way to run tests on one generator. Once that works, you should run `rake run_rspec:examples`. Be aware that this will create a hug number of files under a `/gen-examples` directory. You should be sure to exclude this directory from your IDE and delete it once your testing is done.

### Linting
All linting is performed from the docker container for CI. You will need docker and docker-compose installed locally to lint code changes via the lint container. You can lint locally by running `npm run lint && npm run flow`

* [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
* [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build the `reactonrails_lint` docker image and docker-compose `lint` container. The initial build is slow, but after the install, startup is very quick.

### Linting Commands
Run `rake lint`.

Alternately with Docker:

Run `rake -D docker` to see all docker linting commands for rake. `rake docker:lint` will run all linters. For individual rake linting commands please refer to `rake -D docker` for the list.

You can run specific linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.

`docker-compose run lint bash` sets you up to run from the container command line.

### Docker CI - Test and Linting
Docker CI and Tests containers have a xvfd server automatically started for headless browser testing with selenium and Firefox.

Run `docker-compose build ci` to build the CI container. Run `docker-compose run ci` to start all rspec tests and linting. `docker-compose run --entrypoint=/bin/bash` will override the default CI action and place you inside the CI container in a bash session. This is what is run on Travis-CI.

Run `docker-compose build tests` to build the tests container. Run `docker-compose run tests` to start all RSpec tests.

# Advice for Project Maintainers and Contributors

What do project maintainers do? What sort of work is involved? [sstephenson](https://github.com/sstephenson) wrote in the [turbolinks](https://github.com/turbolinks/turbolinks) repo:

> [Why this is not still fully merged?](https://github.com/turbolinks/turbolinks/pull/124#issuecomment-239826060)
