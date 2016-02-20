# Byebug

[![Version][gem]][gem_url]
[![Quality][gpa]][gpa_url]
[![Coverage][cov]][cov_url]
[![Gratipay][tip]][tip_url]
[![Gitter][irc]][irc_url]

[gem]: https://img.shields.io/gem/v/byebug.svg
[gpa]: https://img.shields.io/codeclimate/github/deivid-rodriguez/byebug.svg
[cov]: https://img.shields.io/codeclimate/coverage/github/deivid-rodriguez/byebug.svg
[tip]: https://img.shields.io/gittip/deivid-rodriguez.svg
[irc]: https://img.shields.io/badge/IRC%20(gitter)-devs%20%26%20users-brightgreen.svg

[gem_url]: https://rubygems.org/gems/byebug
[gpa_url]: https://codeclimate.com/github/deivid-rodriguez/byebug
[cov_url]: https://codeclimate.com/github/deivid-rodriguez/byebug
[tip_url]: https://www.gittip.com/deivid-rodriguez
[irc_url]: https://gitter.im/deivid-rodriguez/byebug

_Debugging in Ruby 2_

Byebug is a simple to use, feature rich debugger for Ruby 2. It uses the new
TracePoint API for execution control and the new Debug Inspector API for call
stack navigation, so it doesn't depend on internal core sources. It's developed
as a C extension, so it's fast. And it has a full test suite so it's reliable.

It allows you to see what is going on _inside_ a Ruby program while it executes
and offers many of the traditional debugging features such as:

* Stepping: Running your program one line at a time.
* Breaking: Pausing the program at some event or specified instruction, to
examine the current state.
* Evaluating: Basic REPL functionality, although [pry] does a better job at
that.
* Tracking: Keeping track of the different values of your variables or the
different lines executed by your program.


## Build Status

Linux & OSX [![Tra][tra]][tra_url]

Windows [![Vey][vey]][vey_url]

[tra]: https://img.shields.io/travis/deivid-rodriguez/byebug.svg?branch=master
[vey]: https://ci.appveyor.com/api/projects/status/github/deivid-rodriguez/byebug?svg=true

[tra_url]: https://travis-ci.org/deivid-rodriguez/byebug
[vey_url]: https://ci.appveyor.com/project/deivid-rodriguez/byebug


## Requirements

* Required: MRI 2.0.0 or higher. For debugging ruby 1.9.3 or older, use
[debugger].

* Recommended:
  - MRI 2.1.7 or higher.
  - MRI 2.2.3 or higher.


## Install

    $ gem install byebug


## Usage

Simply drop

    byebug

wherever you want to start debugging and the execution will stop there. If you
are debugging rails, start the server and once the execution gets to your
`byebug` command you will get a debugging prompt.


## Byebug's commands

    Command     | Aliases      | Subcommands
    ----------- |:------------ |:-----------
    `backtrace` | `bt` `where` |
    `break`     |              |
    `catch`     |              |
    `condition` |              |
    `continue`  |              |
    `delete`    |              |
    `debug`     |              |
    `disable`   |              | `breakpoints` `display`
    `display`   |              |
    `down`      |              |
    `edit`      |              |
    `enable`    |              | `breakpoints` `display`
    `finish`    |              |
    `frame`     |              |
    `help`      |              |
    `history`   |              |
    `info`      |              | `args` `breakpoints` `catch` `display` `file` `line` `program`
    `irb`       |              |
    `kill`      |              |
    `list`      |              |
    `method`    |              | `instance`
    `next`      |              |
    `pry`       |              |
    `quit`      |              |
    `restart`   |              |
    `save`      |              |
    `set`       |              | `autoirb` `autolist` `autopry` `autosave` `basename` `callstyle` `fullpath` `histfile` `histsize` `linetrace` `listsize` `post_mortem` `savefile` `stack_on_error` `width`
    `show`      |              | `autoirb` `autolist` `autopry` `autosave` `basename` `callstyle` `fullpath` `histfile` `histsize` `linetrace` `listsize` `post_mortem` `savefile` `stack_on_error` `width`
    `source`    |              |
    `step`      |              |
    `thread`    |              | `current` `list` `resume` `stop` `switch`
    `tracevar`  |              |
    `undisplay` |              |
    `up`        |              |
    `var`       |              | `all` `constant` `global` `instance` `local`


## Semantic Versioning

Byebug tries to follow [semantic versioning](http://semver.org) and tries to
bump major version only when backwards incompatible changes are released.
Backwards compatibility is targeted to [pry-byebug] and any other plugins
relying on `byebug`.


## Getting Started

Read [byebug's markdown
guide](https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md) to get
started. Proper documentation will be eventually written.


## Related projects

* [pry-byebug] adds `next`, `step`, `finish`, `continue` and `break` commands
to `pry` using `byebug`.
* [ruby-debug-passenger] adds a rake task that restarts Passenger with Byebug
connected.
* [minitest-byebug] starts a byebug session on minitest failures.
* [sublime_debugger] provides a plugin for ruby debugging on Sublime Text.


## Contribute

See [Getting Started with Development](CONTRIBUTING.md).


## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, especially:

* @ko1, author of the awesome TracePoint API for Ruby.
* @cldwalker, [debugger]'s maintainer.
* @denofevil, author of [debase], the starting point of this.
* @kevjames3 for testing, bug reports and the interest in the project.
* @FooBarWidget for working and helping with remote debugging.

[debugger]: https://github.com/cldwalker/debugger
[pry]: https://github.com/pry/pry
[debase]: https://github.com/denofevil/debase
[pry-byebug]: https://github.com/deivid-rodriguez/pry-byebug
[ruby-debug-passenger]: https://github.com/davejamesmiller/ruby-debug-passenger
[minitest-byebug]: https://github.com/kaspth/minitest-byebug
[sublime_debugger]: https://github.com/shuky19/sublime_debugger
