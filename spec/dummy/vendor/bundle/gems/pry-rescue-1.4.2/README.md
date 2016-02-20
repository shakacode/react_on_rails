# pry-rescue

Super-fast debugging for Ruby. (See [Pry to the rescue!](http://cirw.in/blog/pry-to-the-rescue))
<a href="https://travis-ci.org/ConradIrwin/pry-rescue">
<img src="https://secure.travis-ci.org/ConradIrwin/pry-rescue.svg?branch=master" alt="Build status">
</a>

## Introduction

pry-rescue is an implementation of "break on unhandled exception" for Ruby. Whenever an
exception is raised, but not rescued, pry-rescue will automatically open Pry for you:

```ruby
$ rescue examples/example2.rb
From: /home/conrad/0/ruby/pry-rescue/examples/example2.rb @ line 19 Object#beta:

    17: def beta
    18:   y = 30
 => 19:   gamma(1, 2)
    20: end

ArgumentError: wrong number of arguments (2 for 1)
from /home/conrad/0/ruby/pry-rescue/examples/example2.rb:22:in `gamma`
[1] pry(main)>
```

## Installation

You can install `pry-rescue` with RubyGems as normal, and I strongly recommend you also
install `pry-stack_explorer`. See [Known bugs](#known-bugs) for places that won't work.

```
gem install pry-rescue pry-stack_explorer
```

If you're using Bundler, you can add it to your Gemfile in the development group:

```ruby
group :development do
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end
```

## Usage

For simple Ruby scripts, just run them with the `rescue` executable instead of the `ruby`
executable.

```
rescue <script.rb> [arguments..]
```

### Rails

For Rails, use `rescue rails` in place of `rails`, for example:

```
rescue rails server
```

If you're using `bundle exec` the rescue should go after the exec:

```
bundle exec rescue rails server
```

Then whenever an unhandled exception happens inside Rails, a Pry console will open on
stdout. This is the same terminal that you see the Rails logs on, so if you're
using something like [pow](https://pow.cx) then you will run into difficulties.

If you are using non-default http servers like Unicorn or Thin, you can also trigger
this behavior via (after including pry-rescue in your Gemfile):

```
PRY_RESCUE_RAILS=1 bundle exec unicorn
```



You might also be interested in
[better_errors](https://github.com/charliesome/better_errors) which opens consoles in your
browser on unhandled exceptions, and [pry-rails](https://github.com/rweng/pry-rails) which
adds some Rails specific helpers to Pry, and replaces `rails console` by Pry.

### RSpec

If you're using [RSpec](https://rspec.org) or
[respec](https://github.com/oggy/respec), you can open a Pry session on
every test failure using `rescue rspec` or `rescue respec`:

```ruby
$ rescue rspec
From: /home/conrad/0/ruby/pry-rescue/examples/example_spec.rb @ line 9 :

     6:
     7: describe "Float" do
     8:   it "should be able to add" do
 =>  9:     (0.1 + 0.2).should == 0.3
    10:   end
    11: end

RSpec::Expectations::ExpectationNotMetError: expected: 0.3
     got: 0.30000000000000004 (using ==)
[1] pry(main)>
```

Unfortunately using `edit -c` to edit `_spec.rb` files does not yet reload the
code in a way that the `try-again` command can understand. You can still use
`try-again` if you edit code that is not in spec files.

### Minitest

Add the following to your `test_helper.rb` or to the top of your test file.

```ruby
require 'minitest/autorun'
require 'pry-rescue/minitest'
```

Then, when you have a failure, you can use `edit`, `edit -c`, and `edit-method`, then
`try-again` to re-run the tests.

### Rack

If you're using Rack, you should use the middleware instead (though be careful to only
include it in development!):

```
use PryRescue::Rack if ENV["RACK_ENV"] == 'development'
```

## Pry commands

`pry-rescue` adds two commands to Pry. `cd-cause` and `try-again`. In combination with
`edit --method` these can let you fix the problem with your code and verify that the fix
worked without restarting your program.

### cd-cause

If you've run some code in Pry, and an exception was raised, you can use the `cd-cause`
command:

```ruby
[1] pry(main)> foo
RuntimeError: two
from a.rb:4:in `rescue in foo`
[2] pry(main)> cd-cause
From: a.rb @ line 4 Object#foo:

    1: def foo
    2:   raise "one"
    3: rescue => e
 => 4:   raise "two"
    5: end

[3] pry(main)>
```

If that exception was in turn caused by a previous exception you can use
`cd-cause` again to move to the original problem:

```ruby
[3] pry(main)> cd-cause
From: examples/example.rb @ line 4 Object#test:

    4: def test
 => 5:   raise "foo"
    6: rescue => e
    7:   raise "bar"
    8: end

RuntimeError: foo
from examples/example.rb:5:in `test`
[4] pry(main)>
```

To get back from `cd-cause` you can either type `<ctrl+d>` or `cd ..`.

### try-again

Once you've used Pry's `edit` or command to fix your code, you can issue a `try-again`
command to re-run your code. For Rails and rack, this re-runs the request, for minitest
and rspec, it re-runs the current test, for more advanced users this re-runs the
`Pry::rescue{ }` block.

```ruby
[4] pry(main)> edit --method
[5] pry(main)> whereami
From: examples/example.rb @ line 4 Object#test:

    4: def test
 => 5:   puts "foo"
    6: rescue => e
    7:   raise "bar"
    8: end
[6] pry(main)> try-again
foo
```

## Advanced usage

### Block form

If you want more fine-grained control over which parts of your code are rescued, you can
also use the block form:

```ruby
require 'pry-rescue'

def test
  raise "foo"
rescue => e
  raise "bar"
end

Pry.rescue do
  test
end
```
This will land you in a pry-session:

```
From: examples/example.rb @ line 4 Object#test:

    4: def test
    5:   raise "foo"
    6: rescue => e
 => 7:   raise "bar"
    8: end

RuntimeError: bar
from examples/example.rb:7:in `rescue in test`
[1] pry(main)>
```

### Rescuing an exception

Finally. If you're doing your own exception handling, you can ask Pry to open on an exception that you've caught.
For this to work you must be inside a `Pry::rescue{ }` block.

```ruby
def test
  raise "foo"
rescue => e
  Pry::rescued(e)
end

Pry::rescue{ test }

```

## Peeking

Sometimes bugs in your program don't cause exceptions. Instead your program just gets
stuck. Examples include infinite loops, slow network calls, or tests that take a
surprisingly long time to run.

In this case it's useful to be able to open a Pry console when you notice that your
program is not going anywhere. To do this, send your process a `SIGQUIT` using `<ctrl+\>`.

```ruby
cirwin@localhost:/tmp/pry $ ruby examples/loop.rb
^\
Preparing to peek via pry!
Frame number: 0/4

From: ./examples/loop.rb @ line 10 Object#r
    10: def r
    11:   some_var = 13
    12:   loop do
 => 13:     x = File.readlines('lib/pry-rescue.rb')
    14:   end
    15: end
pry (main)>
```

### Advanced peeking

You can configure which signal pry-rescue listens for by default by exporting the
`PRY_PEEK` environment variable that suits your use-case best:

```
export PRY_PEEK=""    # don't autopeek at all
export PRY_PEEK=INT   # peek on SIGINT (<ctrl+c>)
export PRY_PEEK=QUIT  # peek on SIGQUIT
export PRY_PEEK=USR1  # peek on SIGUSR1
export PRY_PEEK=USR2  # peek on SIGUSR2
export PRY_PEEK=EXIT  # peek on program exit
```

If it's only important for one program, then you can also set the environment variable in
Ruby before requiring pry-rescue:

```ruby
ENV['PRY_PEEK'] = '' # disable SIGQUIT handler
require "pry-rescue"
```

Finally, you can enable peeking into programs that do not include pry-rescue by
configuring Ruby to always load one (or several) of these files:

```
export RUBYOPT=-rpry-rescue/peek/int   # peek on SIGINT (<ctrl-c>)
export RUBYOPT=-rpry-rescue/peek/quit  # peek on SIGQUIT (<ctrl-\>)
export RUBYOPT=-rpry-rescue/peek/usr1  # peek on SIGUSR1
export RUBYOPT=-rpry-rescue/peek/usr2  # peek on SIGUSR2
export RUBYOPT=-rpry-rescue/peek/exit  # peek on program exit
```

These last examples relies on having pry-rescue in the load path (i.e. at least in the
gemset, or Gemfile of the program). If that is not true, you can use absolute paths. The
hook files do not require the whole of pry-rescue, nor is any of Pry itself loaded until
you trigger the signal.

```
export RUBYOPT=-r/home/cirwin/src/pry-rescue/lib/pry-rescue/peek/usr2
```

## Known bugs

* Ruby 2.0, 1.9.3, 1.9.2 – no known bugs
* Ruby 1.9.1 — not supported
* Ruby 1.8.7 — occasional incorrect values for self
* REE 1.8.7 — no known bugs
* JRuby 1.7 (1.8 mode and 1.9 mode) — no known bugs
* JRuby 1.6 (1.8 mode and 1.9 mode) — incorrect value for self in NoMethodErrors
* Rubinius (1.8 mode and 1.9 mode) – does not catch some low-level errors (e.g. ZeroDivisionError)

## Meta-fu

Released under the MIT license, see LICENSE.MIT for details. Contributions and bug-reports
are welcome.
