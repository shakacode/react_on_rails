# pry-byebug
[![Version][VersionBadge]][VersionURL]
[![Build][TravisBadge]][TravisURL]
[![Inline docs][InchCIBadge]][InchCIURL]
[![Gittip][GittipBadge]][GittipURL]
[![Coverage][CoverageBadge]][CoverageURL]

_Fast execution control in Pry_

Adds **step**, **next**, **finish** and **continue** commands and
**breakpoints** to [Pry][pry] using [byebug][byebug].

To use, invoke pry normally. No need to start your script or app differently.
Execution will stop in the first statement after your `binding.pry`.

```ruby
def some_method
  puts 'Hello World' # Run 'step' in the console to move here
end

binding.pry
some_method          # Execution will stop here.
puts 'Goodbye World' # Run 'next' in the console to move here.
```


## Requirements

* Required: MRI 2.0.0 or higher. For debugging ruby 1.9.3 or older, use
[pry-debugger][].

* Recommended:
  - MRI 2.1.7 or higher.
  - MRI 2.2.3 or higher.


## Installation

Drop

```ruby
gem 'pry-byebug'
```

in your Gemfile and run

    bundle install

_Make sure you include the gem globally or inside the `:test` group if you plan
to use it to debug your tests!_


## Execution Commands

**step:** Step execution into the next line or method. Takes an optional numeric
argument to step multiple times.

**next:** Step over to the next line within the same frame. Also takes an
optional numeric argument to step multiple lines.

**finish:** Execute until current stack frame returns.

**continue:** Continue program execution and end the Pry session.

**up:** Moves the stack frame up. Takes an optional numeric argument to move
multiple frames.

**down:** Moves the stack frame down. Takes an optional numeric argument to move
multiple frames.

**frame:** Moves to a specific frame. Called without arguments will show the
current frame.

## Matching Byebug Behaviour

If you're coming from Byebug or from Pry-Byebug versions previous to 3.0, you
may be lacking the 'n', 's', 'c' and 'f' aliases for the stepping commands.
These aliases were removed by default because they usually conflict with
scratch variable names. But it's very easy to reenable them if you still want
them, just add the following shortcuts to your `~/.pryrc` file:

```ruby
if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end
```

Also, you might find useful as well the repeat the last command by just hitting
the `Enter` key (e.g., with `step` or `next`). To achieve that, add this to
your `~/.pryrc` file:

```ruby
# Hit Enter to repeat last command
Pry::Commands.command /^$/, "repeat last command" do
  _pry_.run_command Pry.history.to_a.last
end
```


## Breakpoints

You can set and adjust breakpoints directly from a Pry session using the
`break` command:

**break:** Set a new breakpoint from a line number in the current file, a file
and line number, or a method. Pass an optional expression to create a
conditional breakpoint. Edit existing breakpoints via various flags.

Examples:

```ruby
break SomeClass#run            # Break at the start of `SomeClass#run`.
break Foo#bar if baz?          # Break at `Foo#bar` only if `baz?`.
break app/models/user.rb:15    # Break at line 15 in user.rb.
break 14                       # Break at line 14 in the current file.

break --condition 4 x > 2      # Change condition on breakpoint #4 to 'x > 2'.
break --condition 3            # Remove the condition on breakpoint #3.

break --delete 5               # Delete breakpoint #5.
break --disable-all            # Disable all breakpoints.

break                          # List all breakpoints.
break --show 2                 # Show details about breakpoint #2.
```

Type `break --help` from a Pry session to see all available options.


## Credits

* Gopal Patel (@nixme), creator of [pry-debugger][], and everybody who
contributed to it. pry-byebug is a fork of pry-debugger so it wouldn't exist as
it is without those contributions.
* John Mair (@banister), creator of [pry][].

Patches and bug reports are welcome.

[pry]: http://pry.github.com
[byebug]: https://github.com/deivid-rodriguez/byebug
[pry-debugger]: https://github.com/nixme/pry-debugger
[pry-stack_explorer]: https://github.com/pry/pry-stack_explorer

[VersionBadge]: https://badge.fury.io/rb/pry-byebug.svg
[VersionURL]: http://badge.fury.io/rb/pry-byebug
[TravisBadge]: https://secure.travis-ci.org/deivid-rodriguez/pry-byebug.svg
[TravisURL]: http://travis-ci.org/deivid-rodriguez/pry-byebug
[InchCIBadge]: http://inch-ci.org/github/deivid-rodriguez/pry-byebug.svg?branch=master
[InchCIURL]: http://inch-ci.org/github/deivid-rodriguez/pry-byebug
[GittipBadge]: http://img.shields.io/gittip/deivid-rodriguez.svg
[GittipURL]: https://www.gittip.com/deivid-rodriguez
[CoverageBadge]: https://img.shields.io/codeclimate/coverage/github/deivid-rodriguez/pry-byebug.svg
[CoverageURL]: https://codeclimate.com/github/deivid-rodriguez/pry-byebug
