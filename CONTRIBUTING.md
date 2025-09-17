# Tips for Contributors

- [docs/contributor-info/Releasing](./docs/contributor-info/releasing.md) for instructions on releasing.
- [docs/contributor-info/pull-requests](./docs/contributor-info/pull-requests.md)
- See other docs in [docs/contributor-info](./docs/contributor-info)

## Prerequisites

- [Yalc](https://github.com/whitecolor/yalc) must be installed globally for most local development.
- After updating code via Git, to prepare all examples:

```sh
cd react_on_rails/
bundle && yarn && rake shakapacker_examples:gen_all && rake node_package && rake
```

See [Dev Initial Setup](#dev-initial-setup) below for, well... initial setup,
and [Running tests](#running-tests) for more details on running tests.

# IDE/IDE SETUP

It's critical to configure your IDE/editor to ignore certain directories. Otherwise, your IDE might slow to a crawl!

- /coverage
- /tmp
- /gen-examples
- /node_package/lib
- /node_modules
- /spec/dummy/app/assets/webpack
- /spec/dummy/log
- /spec/dummy/node_modules
- /spec/dummy/client/node_modules
- /spec/dummy/tmp
- /spec/react_on_rails/dummy-for-generators

# Configuring your test app to use your local fork

You can test the `react-on-rails` gem using your own external test app or the gem's internal `spec/dummy` app. The `spec/dummy` app is an example of the various setup techniques you can use with the gem.

```text
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

## Testing the Node package for React on Rails via Yalc

In addition to testing the Ruby parts out, you can also test the Node package parts of the gem with an external application. First, be **sure** to build the NPM package:

```sh
cd react_on_rails/
yarn

# Update the lib directory with babel compiled files
yarn run build-watch
```

You need to do this once:

```
# Will send the updates to other folders
yalc publish
cd spec/dummy
yalc add react-on-rails
```

The workflow is:

1. Make changes to the node package.
2. **CRITICAL**: Run yalc push to send updates to all linked apps:

```
cd <top dir>
# Will send the updates to other folders - MUST DO THIS AFTER ANY CHANGES
yalc push
cd spec/dummy

# Will update from yalc
yarn
```

**⚠️ Common Mistake**: Forgetting to run `yalc push` after making changes to React on Rails source code will result in test apps not receiving updates, making it appear that your changes have no effect.

When you run `yalc push`, you'll get an informative message

```
✗ yalc push
react-on-rails@12.0.0-12070fd1 published in store.
Pushing react-on-rails@12.0.0 in /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy
Package react-on-rails@12.0.0-12070fd1 added ==> /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy/node_modules/react-on-rails.
Don't forget you may need to run yarn after adding packages with yalc to install/update dependencies/bin scripts.
```

#### Example: Testing NPM changes with the dummy app

1. Add `console.log('Hello!')` to [clientStartup.ts, function render](https://github.com/shakacode/react_on_rails/blob/master/node_package/src/clientStartup.ts in `/node_package/src/clientStartup.js` to confirm we're getting an update to the node package client side. Do the same for function `serverRenderReactComponent` in `/node_package/src/serverRenderReactComponent.ts`.
2. Refresh the browser if the server is already running or start the server using `foreman start` from `react_on_rails/spec/dummy` and navigate to `http://localhost:5000/`. You will now see the `Hello!` message printed in the browser's console. If you did not see that message, then review the steps above for the workflow of making changes and pushing them via yalc.

# Development Setup for Gem and Node Package Contributors

## Dev Initial Setup

### Prereqs

After checking out the repo, making sure you have Ruby and Node version managers set up (such as rvm and nvm, or rbenv and nodenv, etc.), cd to `spec/dummy` and run `bin/setup` to install ruby dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Local Node Package

Note, the example and dummy apps will use your local `node_packages` folder as the `react-on-rails` node package. This will also be done automatically for you via the `rake examples:gen_all` rake task.

_Side note: It's critical to use the alias section of the Webpack config to avoid a double inclusion error. This has already been done for you in the example and dummy apps, but for reference:_

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

Or run this, which builds the Yarn package, then the Webpack files for `spec/dummy`, and runs tests in
`spec/dummy`.

```sh
# Optionally change default capybara driver
export DRIVER=selenium_firefox
cd react_on_rails/
yarn run dummy:spec
```

To convert the development environment over to Shakapacker v6 instead of the default Shakapacker v8:

```sh
# Optionally change default capybara driver
export DRIVER=selenium_firefox
cd react_on_rails/
script/convert
yarn run dummy:spec
```

## Running tests

### JS tests

```sh
cd react_on_rails/
yarn run test
```

### spec/dummy tests

```sh
cd react_on_rails/spec/dummy
rspec
```

### Linting, type checking and JS tests together

```sh
cd react_on_rails/
yarn run check
```

## Development Commands

### Code Formatting

To format JavaScript/TypeScript files with Prettier:

```sh
yarn start format
```

To check formatting without fixing:

```sh
yarn start format.listDifferent
```

### Linting

Run all linters (ESLint and RuboCop):

```sh
rake lint
```

Run only RuboCop:

```sh
rake lint:rubocop
```

Run only ESLint:

```sh
yarn run lint
```

### Starting the Dummy App

To run the dummy app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start` with one of the Procfiles. If you don't do this, then `webpack` will not generate a new bundle, and you will be seriously confused when you change JavaScript and the app does not change. If you change the Webpack configs, then you need to restart Foreman. If you change the JS code for react-on-rails, you need to run `yarn run build` in the project root.

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

Then run `bundle`.

The main installer can be run with `./bin/rails generate react_on_rails:install`

Then use yalc to add the npm module.

Be sure that your ran this first at the top level of React on Rails

```
yalc publish
```

Then add the node package to your test app:

```
yalc add react-on-rails
```

### Testing the Generator

The generators are covered by generator tests using Rails's generator testing helpers, but it never hurts to do a sanity check and explore the API. See [generator-testing.md](docs/contributor-info/generator-testing.md) for a script on how to run the generator on a fresh project.

`rake run_rspec:shakapacker_examples_basic` is a great way to run tests on one generator. Once that works, you should run `rake run_rspec:shakapacker_examples`. Be aware that this will create a huge number of files under a `/gen-examples` directory. You should be sure to exclude this directory from your IDE and delete it once your testing is done.

#### Manual Generator Testing Workflow

For comprehensive testing of generator changes, use this manual testing workflow with dedicated test applications:

**1. Set up test application with clean baseline:**

```bash
# Create a test Rails app
mkdir -p {project_dir}/test-app
cd {project_dir}/test-app
rails new . --skip-javascript

# Set up for testing the generator
echo 'gem "react_on_rails", path: "../react_on_rails"' >> Gemfile
yalc add react-on-rails

# Create a clean baseline tag for testing
git init && git add . && git commit -m "Initial commit"
git tag generator_testing_base
bundle install

# Clean reset to baseline state
git clean -fd && git reset --hard && git clean -fd
```

**2. Test generator commits systematically:**

When testing specific generator improvements or fixes, test both Shakapacker scenarios:

**Scenario A: No Shakapacker installed (fresh Rails app)**

```bash
# Reset to clean baseline before each test
git clean -fd && git reset --hard generator_testing_base && git clean -fd

# Ensure no Shakapacker in Gemfile (remove if present)
# Edit Gemfile to update gem path: gem 'react_on_rails', path: '../path/to/main/repo'
bundle install

# Run generator - should install Shakapacker automatically
./bin/rails generate react_on_rails:install

# Verify Shakapacker was added to Gemfile and installed correctly
```

**Scenario B: Shakapacker already installed**

```bash
# Reset to clean baseline
git clean -fd && git reset --hard generator_testing_base && git clean -fd

# Add Shakapacker to Gemfile
bundle add shakapacker --strict

# Run Shakapacker installer first
./bin/rails shakapacker:install

# Edit Gemfile to update gem path: gem 'react_on_rails', path: '../path/to/main/repo'
bundle install

# Run generator - should detect existing Shakapacker
./bin/rails generate react_on_rails:install

# Verify generator adapts to existing Shakapacker setup
```

**3. Document testing results:**

For each commit tested, document:

- Generator execution success/failure for both scenarios
- Shakapacker installation/detection behavior
- Component rendering in browser
- Console output and warnings
- File generation differences between scenarios
- Specific issues found

This systematic approach ensures generator changes work correctly whether Shakapacker is pre-installed or needs to be installed by the generator.

#### Testing Generator with Yalc for React Component Functionality

When testing the install generator with new Rails apps, you need to use **yalc** for the JavaScript package to ensure React components work correctly. The Ruby gem path reference is insufficient for client-side rendering.

**Problem**: Using only the gem path (`gem "react_on_rails", path: "../path"`) in a new Rails app results in React components not mounting on the client side, even though server-side rendering works fine.

**Solution**: Use both gem path and yalc for complete testing:

```ruby
# In test app's Gemfile
gem 'react_on_rails', path: '../relative/path/to/react_on_rails'
```

```bash
# After running the install generator AND after making any changes to the React on Rails source code
cd /path/to/react_on_rails
npm run build
npx yalc publish
# CRITICAL: Push changes to all linked apps
npx yalc push

cd /path/to/test_app
npm install

# Restart development server
bin/dev
```

**⚠️ CRITICAL DEBUGGING NOTE:**
Always run `yalc push` after making changes to React on Rails source code. Without this step, your test app won't receive the updated package, leading to confusing behavior where changes appear to have no effect.

**Alternative to Yalc: npm pack (More Reliable)**
For a more reliable alternative that exactly mimics real package installation:

```bash
# In react_on_rails directory
npm run build
npm pack  # Creates react-on-rails-15.0.0.tgz

# In test app directory
npm install ../path/to/react_on_rails/react-on-rails-15.0.0.tgz
```

This approach:

- ✅ Exactly mimics real package installation
- ✅ No symlink issues across different filesystems
- ✅ More reliable for CI/CD testing
- ⚠️ Requires manual step after each change (can be scripted)

**Why this is needed**:

- The gem provides Rails integration and server-side rendering
- Yalc provides the complete JavaScript client library needed for component mounting
- Without yalc, you'll see empty divs where React components should render

**Verification**:

- Visit the hello_world page in browser
- Check browser console for "RENDERED HelloWorld to dom node" success message
- Confirm React component is interactive (input field updates name display)

**Development Mode Console Output**:

- `bin/dev` (HMR): Shows HMR warnings and resource preload warnings (expected)
- `bin/dev static`: Shows only resource preload warnings (cleaner output)
- `bin/dev prod`: Cleanest output with minimal warnings (production-like environment)

**Note**: Resource preload warnings in development modes are normal and can be ignored. They occur because Shakapacker generates preload tags but scripts load asynchronously. Production mode eliminates most of these warnings.

#### Generator Testing Troubleshooting

**Common Issues and Solutions:**

1. **React components not rendering (empty divs)**

   - **Cause**: Missing yalc setup for JavaScript package
   - **Solution**: Follow yalc setup steps above after running generator

2. **Generator fails with Shakapacker errors**

   - **Cause**: Conflicting Shakapacker versions or incomplete installation
   - **Solution**: Clean reset and ensure consistent Shakapacker version across tests

3. **Babel configuration conflicts during yalc development**

   - **Cause**: Both `babel.config.js` and `package.json` "babel" section defining presets
   - **Solution**: Remove "babel" section from `package.json`, keep only `babel.config.js`

4. **"Package.json not found" errors**

   - **Cause**: Generator trying to access non-existent package.json files
   - **Solution**: Test with commits that fix this specific issue (e.g., bc69dcd0)

5. **Port conflicts during testing**
   - **Cause**: Multiple development servers running
   - **Solution**: Run `bin/dev kill` before starting new test servers

**Testing Best Practices:**

- Always use the double clean command: `git clean -fd && git reset --hard && git clean -fd`
- Test both Shakapacker scenarios for comprehensive coverage
- Document exact error messages and steps to reproduce
- Verify React component interactivity, not just rendering
- Test all development modes: `bin/dev`, `bin/dev static`, `bin/dev prod`

## Pre-Commit Requirements

**CRITICAL**: Before committing any changes, always run the following commands to ensure code quality:

```bash
# Navigate to the main react_on_rails directory
cd react_on_rails/

# Run Prettier for JavaScript/TypeScript formatting
yarn run format

# Run ESLint for JavaScript/TypeScript linting
yarn run lint

# Run RuboCop for Ruby linting and formatting
rake lint:rubocop

# Or run all linters together
rake lint
```

**Automated checks:**

- Format all JavaScript/TypeScript files with Prettier
- Check and fix linting issues with ESLint
- Check and fix Ruby style issues with RuboCop
- Ensure all tests pass before pushing

**Tip**: Set up your IDE to run these automatically on save to catch issues early.

## 🤖 Best Practices for AI Coding Agents

**CRITICAL WORKFLOW** to prevent CI failures:

### 1. **After Making Code Changes**

```bash
# Auto-fix all linting violations after code changes
rake autofix
```

### 2. **Common AI Agent Mistakes**

❌ **DON'T:**

- Commit code that hasn't been linted locally
- Ignore formatting rules when creating new files
- Add manual formatting that conflicts with Prettier/RuboCop

✅ **DO:**

- Run `rake lint` after any code changes
- Use `rake autofix` to automatically fix all linting violations
- Create new files that follow existing patterns
- Test locally before committing

### 4. **Template File Best Practices**

When creating new template files (`.jsx`, `.rb`, etc.):

1. Copy existing template structure and patterns
2. Run `yarn run eslint . --fix` immediately after creation
3. Verify with `rake lint` before committing

### 5. **RuboCop Complexity Issues**

For methods with high ABC complexity (usually formatting/display methods):

```ruby
# rubocop:disable Metrics/AbcSize
def complex_formatting_method
  # ... method with lots of string interpolation/formatting
end
# rubocop:enable Metrics/AbcSize
```

**Remember**: Failing CI wastes time and resources. Always lint locally first!

### Linting

All linting is performed from the docker container for CI. You will need docker and docker-compose installed locally to lint code changes via the lint container. You can lint locally by running `npm run lint && npm run flow`

- [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
- [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build the `reactonrails_lint` docker image and docker-compose `lint` container. The initial build is slow, but after the install, startup is very quick.

### Linting Commands

Run `rake lint`.

Alternately with Docker:

Run `rake -D docker` to see all docker linting commands for rake. `rake docker:lint` will run all linters. For individual rake linting commands please refer to `rake -D docker` for the list.

You can run specific linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.

`docker-compose run lint bash` sets you up to run from the container command line.

### Updating Rubocop

2 files require updating to update the Rubocop version:

1. `react_on_rails.gemspec`
2. `spec/dummy/Gemfile`

### Docker CI - Test and Linting

Docker CI and Tests containers have a xvfd server automatically started for headless browser testing with selenium and Firefox.

Run `docker-compose build ci` to build the CI container. Run `docker-compose run ci` to start all rspec tests and linting. `docker-compose run --entrypoint=/bin/bash` will override the default CI action and place you inside the CI container in a bash session. This is what is run on Travis-CI.

Run `docker-compose build tests` to build the tests container. Run `docker-compose run tests` to start all RSpec tests.

# Advice for Project Maintainers and Contributors

What do project maintainers do? What sort of work is involved? [sstephenson](https://github.com/sstephenson) wrote in the [turbolinks](https://github.com/turbolinks/turbolinks) repo:

> [Why this is not still fully merged?](https://github.com/turbolinks/turbolinks/pull/124#issuecomment-239826060)

# 📦 Demo Naming and README Standards

To keep our React on Rails demos clear, discoverable, and SEO-friendly, all demo repos follow a standardized naming and documentation structure.

---

## ✅ Repository Naming Convention

Use the format:

```
react_on_rails-demo-v[REACT_ON_RAILS_VERSION]-[key-topics]
```

**Examples:**

- `react_on_rails-demo-v15-ssr-auto-registration-bundle-splitting`
- `react_on_rails-demo-v15-react-server-components`
- `react_on_rails-demo-v15-typescript-setup`
- `react_on_rails-demo-v15-cypress-setup`

**Why this format?**

- Clear versioning and purpose
- Easy to discover in GitHub, search engines, and documentation
- Consistent prefix for grouping demos together

---

## 📝 README Title Format

```
# React on Rails Demo: [Topics] with v[VERSION] and Rails [VERSION]
```

**Example:**

```
# React on Rails Demo: SSR, Auto-Registration & Bundle Splitting with v15 and Rails 8
```

---

## 📄 README Description Template

```
A fully working demo of React on Rails v[VERSION] on Rails [VERSION], showcasing [topics].

✅ Includes:
- [Topic 1]
- [Topic 2]
- [Topic 3]

📂 Repo name: `react_on_rails-demo-v[VERSION]-[topics]`

📚 Part of the [React on Rails Demo Series](https://github.com/shakacode?tab=repositories&q=react_on_rails-demo)
```

**Example:**

```
A fully working demo of React on Rails v15 on Rails 8, showcasing server-side rendering, file-system-based auto-registration, and intelligent bundle splitting.

✅ Includes:
- Server-Side Rendering (SSR)
- Auto-discovered components based on file structure
- Lightweight vs. heavy component splitting
- Fix for “package.json not found” install bug

📂 Repo name: `react_on_rails-demo-v15-ssr-auto-registration-bundle-splitting`

📚 Part of the [React on Rails Demo Series](https://github.com/shakacode?tab=repositories&q=react_on_rails-demo)
```
