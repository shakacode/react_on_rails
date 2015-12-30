# Tips for Contributors

# IDE/IDE SETUP
It's critical to configure your IDE/editor to ignore certain directories. Otherwise your IDE might slow to a crawl!

* /coverage
* /examples
* /node_modules



# Development Setup for Gem and Node Package Contributors

## Checklist before Committing
1. `rake ci`: runs all linters and specs (you need Docker setup, see below)
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?

## Dev Initial Setup

### Prereqs
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), cd to `spec/dummy` and run `bin/setup` to install ruby dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Npm link

By the following steps, the node package code of react-on-rails is directly coming from `node_package/lib`

```sh
cd <top level>
npm link
cd spec/dummy/client
npm link react-on-rails
```

*Side note: It's critical to use the alias section of the webpack config to avoid the double inclusion error:*

```js
  resolve: {
    alias: {
      react: path.resolve('./node_modules/react'),
    },
  },
```

### Install npm dependencies and build the npm package for react-on-rails 

```sh
cd <top level>
npm i
npm run build
cd spec/dummy
npm i
```

### Run npm JS tests

```sh
cd <top level>
npm test
```

### Run spec/dummy tests

```sh
cd spec/dummy
npm run test
```
 
### Run most tests and linting

```
cd <top level>
node_package/scripts/ci
```


### Starting the Dummy App
To run the test app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start`. If you don't do this, then `webpack` will not generate a new bundle, and you will be seriously confused when you change JavaScript and the app does not change. If you change the webpack configs, then you need to restart foreman. If you change the JS code for react-on-rails, you need to run `node_package/scripts/build`. Since the react-on-rails package should be sym linked, you don't have to `npm i react-on-rails` after every change.

### RSpec Testing
Run `rake` for testing the gem and `spec/dummy`. Otherwise, the `rspec` command only works for testing within the sample apps, like `spec/dummy`.

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

After running a test, you can view the coverage results SimpleCov reports by opening `coverage/index.html`.

### Debugging
Start the sample app like this for some debug printing:

```bash
TRACE_REACT_ON_RAILS=true && foreman start
```

### Install Generator
In your Rails app add this gem with a path to your fork.

```
gem 'react_on_rails', path: '../relative/path/to/react_on_rails'
```

The main installer can be run with ```rails generate react_on_rails:install```

### Testing the Generator
The generators are covered by generator tests using Rails's generator testing helpers, but it never hurts to do a sanity check and explore the API. See [generator_testing_script.md](generator_testing_script.md) for a script on how to run the generator on a fresh project.

### Linting
All linting is performed from the docker container for CI. You will need docker and docker-compose installed locally to lint code changes via the lint container. You can lint locally by running `node_package/scripts/lint`

* [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
* [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build the `reactonrails_lint` docker image and docker-compose `lint` container. The initial build is slow, but after the install, startup is very quick.

### Linting Commands
Run `rake -D docker` to see all docker linting commands for rake. `rake docker:lint` will run all linters. For individual rake linting commands please refer to `rake -D docker` for the list.

You can run specific linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.

`docker-compose run lint bash` sets you up to run from the container command line. 

### Docker CI - Test and Linting
Docker CI and Tests containers have a xvfd server automatically started for headless browser testing with selenium and Firefox.

Run `docker-compose build ci` to build the CI container. Run `docker-compose run ci` to start all rspec tests and linting. `docker-compose run --entrypoint=/bin/bash` will override the default CI action and place you inside the CI container in a bash session. This is what is run on Travis-CI.

Run `docker-compose build tests` to build the tests container. Run `docker-compose run tests` to start all rspec tests.

# NPM Releasing
