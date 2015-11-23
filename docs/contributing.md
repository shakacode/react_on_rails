# Tips for Contributors

## Development Setup for Gem Contributors

### Checklist before Committing
1. `rake ci`: runs all linters and specs (you need Docker setup, see below)
2. Did you need any more tests for your change?
3. Did you document your change? Update the README.md?

### Initial Setup
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), 
cd to `spec/dummy` and run `bin/setup` to install dependencies.  
You can also run `bin/console` for an interactive prompt that will allow you to experiment. 

### Starting the Dummy App
To run the test app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start`. 
If you don't do this, then `webpack` will not generate a new bundle, 
and you will be seriously confused when you change JavaScript and the app does not change. 

### Install and Release
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, 
update the version number in `version.rb`, and then run `bundle exec rake release`, 
which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### RSpec Testing
Run `rake` for testing the gem and `spec/dummy` and `spec/dummy-react-013`. Otherwise, the `rspec` command only works for testing within the sample apps, like `spec/dummy`.

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
gem 'react_on_rails', path: '/your_fork'
```

The main installer can be run with ```rails generate react_on_rails:install```

### Testing the Generator
The generators are covered by generator tests using Rails's generator testing helpers, but it never hurts to do a sanity check and explore the API. See [generator_testing_script.md](generator_testing_script.md) for a script on how to run the generator on a fresh project.

## Updating New Versions of the Gem

See https://github.com/svenfuchs/gem-release

```bash
gem bump
cd spec/dummy
bundle
git commit -am "Updated Gemfile.lock"
cd ../..
gem tag
gem release
```

### Linting
All linting is performed from the docker container. You will need docker and docker-compose installed
locally to lint code changes via the lint container. 

* [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
* [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build
the `reactonrails_lint` docker image and docker-compose `lint` container. The inital build is slow,
but after the install, startup is very quick.

### Linting Commands
Run `rake -D docker` to see all docker linting commands for rake. `rake docker:lint` will run all linters.
For individual rake linting commands please refer to `rake -D docker` for the list.
You can run specfic linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.
`docker-compose run lint bash` sets you up to run from the container command line. 

### Docker CI - Test and Linting
Docker CI and Tests containers have a xvfd server automatically started for headless browser testing with selenium and firefox.

Run `docker-compose build ci` to build the ci container. Run `docker-compose run ci` to start all
rspec test and linting. `docker-compose run --entrypoint=/bin/bash` will override the default ci action and place
you inside the ci container in a bash session. This is what is run on Travis-ci.

Run `docker-compose build tests` to build the tests container. Run `docker-compose run tests` to start all
rspec tests. 
