# Spring

[![Build Status](https://travis-ci.org/rails/spring.svg?branch=master)](https://travis-ci.org/rails/spring)
[![Gem Version](https://badge.fury.io/rb/spring.svg)](http://badge.fury.io/rb/spring)

Spring is a Rails application preloader. It speeds up development by
keeping your application running in the background so you don't need to
boot it every time you run a test, rake task or migration.

## Features

* Totally automatic; no need to explicitly start and stop the background process
* Reloads your application code on each run
* Restarts your application when configs / initializers / gem
  dependencies are changed

## Compatibility

* Ruby versions: MRI 1.9.3, MRI 2.0, MRI 2.1
* Rails versions: 4.0+ (in Rails 4.1 and up Spring is included by default)

Spring makes extensive use of `Process.fork`, so won't be able to
provide a speed up on platforms which don't support forking (Windows, JRuby).

## Walkthrough

### Setup

Add spring to your Gemfile:

``` ruby
gem "spring", group: :development
```

(Note: using `gem "spring", git: "..."` *won't* work and is not a
supported way of using spring.)

It's recommended to 'springify' the executables in your `bin/`
directory:

```
$ bundle install
$ bundle exec spring binstub --all
```

This generates a `bin/spring` executable, and inserts a small snippet of
code into relevant existing executables. The snippet looks like this:

``` ruby
begin
  load File.expand_path('../spring', __FILE__)
rescue LoadError
end
```

On platforms where spring is installed and supported, this snippet
hooks spring into the execution of commands. In other cases, the snippet
will just be silently ignored and the lines after it will be executed as
normal.

If you don't want to prefix every command you type with `bin/`, you
can [use direnv](https://github.com/zimbatm/direnv#the-stdlib) to
automatically add `./bin` to your `PATH` when you `cd` into your application.
Simply create an `.envrc` file with the command `PATH_add bin` in your
Rails directory.

### Usage

For this walkthrough I've generated a new Rails application, and run
`rails generate scaffold post name:string`.

Let's run a test:

```
$ time bin/rake test test/controllers/posts_controller_test.rb
Running via Spring preloader in process 2734
Run options:

# Running tests:

.......

Finished tests in 0.127245s, 55.0121 tests/s, 78.5887 assertions/s.

7 tests, 10 assertions, 0 failures, 0 errors, 0 skips

real    0m2.165s
user    0m0.281s
sys     0m0.066s
```

That wasn't particularly fast because it was the first run, so spring
had to boot the application. It's now running:

```
$ bin/spring status
Spring is running:

26150 spring server | spring-demo-app | started 3 secs ago
26155 spring app    | spring-demo-app | started 3 secs ago | test mode
```

The next run is faster:

```
$ time bin/rake test test/controllers/posts_controller_test.rb
Running via Spring preloader in process 8352
Run options:

# Running tests:

.......

Finished tests in 0.176896s, 39.5714 tests/s, 56.5305 assertions/s.

7 tests, 10 assertions, 0 failures, 0 errors, 0 skips

real    0m0.610s
user    0m0.276s
sys     0m0.059s
```

If we edit any of the application files, or test files, the changes will
be picked up on the next run without the background process having to
restart. This works in exactly the same way as the code reloading
which allows you to refresh your browser and instantly see changes during
development.

But if we edit any of the files which were used to start the application
(configs, initializers, your gemfile), the application needs to be fully
restarted. This happens automatically.

Let's "edit" `config/application.rb`:

```
$ touch config/application.rb
$ bin/spring status
Spring is running:

26150 spring server | spring-demo-app | started 36 secs ago
26556 spring app    | spring-demo-app | started 1 sec ago | test mode
```

The application detected that `config/application.rb` changed and
automatically restarted itself.

If we run a command that uses a different environment, then that
environment gets booted up:

```
$ bin/rake routes
Running via Spring preloader in process 2363
    posts GET    /posts(.:format)          posts#index
          POST   /posts(.:format)          posts#create
 new_post GET    /posts/new(.:format)      posts#new
edit_post GET    /posts/:id/edit(.:format) posts#edit
     post GET    /posts/:id(.:format)      posts#show
          PUT    /posts/:id(.:format)      posts#update
          DELETE /posts/:id(.:format)      posts#destroy

$ bin/spring status
Spring is running:

26150 spring server | spring-demo-app | started 1 min ago
26556 spring app    | spring-demo-app | started 42 secs ago | test mode
26707 spring app    | spring-demo-app | started 2 secs ago | development mode
```

There's no need to "shut down" spring. This will happen automatically
when you close your terminal. However if you do want to do a manual shut
down, use the `stop` command:

```
$ bin/spring stop
Spring stopped.
```

### Removal

To remove spring:

* 'Unspring' your bin/ executables: `bin/spring binstub --remove --all`
* Remove spring from your Gemfile

### Deployment

You must not install Spring on your production environment. To prevent it from
being installed, provide the `--without development test` argument to the
`bundle install` command which is used to install gems on your production
machines:

```
$ bundle install --without development test
```

## Commands

### `rake`

Runs a rake task. Rake tasks run in the `development` environment by
default. You can change this on the fly by using the `RAILS_ENV`
environment variable. The environment is also configurable with the
`Spring::Commands::Rake.environment_matchers` hash. This has sensible
defaults, but if you need to match a specific task to a specific
environment, you'd do it like this:

``` ruby
Spring::Commands::Rake.environment_matchers["perf_test"] = "test"
Spring::Commands::Rake.environment_matchers[/^perf/]     = "test"

# To change the environment when you run `rake` with no arguments
Spring::Commands::Rake.environment_matchers[:default] = "development"
```

### `rails console`, `rails generate`, `rails runner`

These execute the rails command you already know and love. If you run
a different sub command (e.g. `rails server`) then spring will automatically
pass it through to the underlying `rails` executable (without the
speed-up).

### Additional commands

You can add these to your Gemfile for additional commands:

* [spring-commands-rspec](https://github.com/jonleighton/spring-commands-rspec)
* [spring-commands-cucumber](https://github.com/jonleighton/spring-commands-cucumber)
* [spring-commands-spinach](https://github.com/jvanbaarsen/spring-commands-spinach)
* [spring-commands-testunit](https://github.com/jonleighton/spring-commands-testunit) - useful for
  running `Test::Unit` tests on Rails 3, since only Rails 4 allows you
  to use `rake test path/to/test` to run a particular test/directory.
* [spring-commands-teaspoon](https://github.com/alejandrobabio/spring-commands-teaspoon.git)
* [spring-commands-m](https://github.com/gabrieljoelc/spring-commands-m.git)
* [spring-commands-rubocop](https://github.com/p0deje/spring-commands-rubocop)

## Use without adding to bundle

If you don't want spring-related code checked into your source
repository, it's possible to use spring without adding to your Gemfile.
However, using spring binstubs without adding spring to the Gemfile is not
supported.

To use spring like this, do a `gem install spring` and then prefix
commands with `spring`. For example, rather than running `bin/rake -T`,
you'd run `spring rake -T`.

## Temporarily disabling Spring

If you're using Spring binstubs, but temporarily don't want commands to
run through Spring, set the `DISABLE_SPRING` environment variable.

## Class reloading

Spring uses Rails' class reloading mechanism
(`ActiveSupport::Dependencies`) to keep your code up to date between
test runs. This is the same mechanism which allows you to see changes
during development when you refresh the page. However, you may never
have used this mechanism with your `test` environment before, and this
can cause problems.

It's important to realise that code reloading means that the constants
in your application are *different objects* after files have changed:

```
$ bin/rails runner 'puts User.object_id'
70127987886040
$ touch app/models/user.rb
$ bin/rails runner 'puts User.object_id'
70127976764620
```

Suppose you have an initializer `config/initializers/save_user_class.rb`
like so:

``` ruby
USER_CLASS = User
```

This saves off the *first* version of the `User` class, which will not
be the same object as `User` after the code has been reloaded:

```
$ bin/rails runner 'puts User == USER_CLASS'
true
$ touch app/models/user.rb
$ bin/rails runner 'puts User == USER_CLASS'
false
```

So to avoid this problem, don't save off references to application
constants in your initialization code.

## Configuration

Spring will read `~/.spring.rb` and `config/spring.rb` for custom
settings. Note that `~/.spring.rb` is loaded *before* bundler, but
`config/spring.rb` is loaded *after* bundler. So if you have any
`spring-commands-*` gems installed that you want to be available in all
projects without having to be added to the project's Gemfile, require
them in your `~/.spring.rb`.

`config/spring_client.rb` is also loaded before bundler and before a
server process is started, it can be used to add new top-level commands.

### Application root

Spring must know how to find your Rails application. If you have a
normal app everything works out of the box. If you are working on a
project with a special setup (an engine for example), you must tell
Spring where your app is located:

```ruby
Spring.application_root = './test/dummy'
```

### Running code before forking

There is no `Spring.before_fork` callback. To run something before the
fork, you can place it in `~/.spring.rb` or `config/spring.rb` or in any of the files
which get run when your application initializes, such as
`config/application.rb`, `config/environments/*.rb` or
`config/initializers/*.rb`.

### Running code after forking

You might want to run code after Spring forked off the process but
before the actual command is run. You might want to use an
`after_fork` callback if you have to connect to an external service,
do some general cleanup or set up dynamic configuration.

```ruby
Spring.after_fork do
  # run arbitrary code
end
```

If you want to register multiple callbacks you can simply call
`Spring.after_fork` multiple times with different blocks.

### Watching files and directories

Spring will automatically detect file changes to any file loaded when the server
boots. Changes will cause the affected environments to be restarted.

If there are additional files or directories which should trigger an
application restart, you can specify them with `Spring.watch`:

```ruby
Spring.watch "config/some_config_file.yml"
```

By default Spring polls the filesystem for changes once every 0.2 seconds. This
method requires zero configuration, but if you find that it's using too
much CPU, then you can use event-based file system listening by
installing the
[spring-watcher-listen](https://github.com/jonleighton/spring-watcher-listen)
gem.

### Quiet output

To disable the "Running via Spring preloader" message which is shown each time
a command runs:

``` ruby
Spring.quiet = true
```

## Troubleshooting

If you want to get more information about what spring is doing, you can
specify a log file with the `SPRING_LOG` environment variable:

```
spring stop # if spring is already running
export SPRING_LOG=/tmp/spring.log
spring rake -T
```
