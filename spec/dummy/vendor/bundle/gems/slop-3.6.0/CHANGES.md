3.6.0 (2014-06-18)
------------------

* Add example of rest arguments usage in the readme file #139
* Default values on options are printed in the help message #134

3.5.0 (2014-03-12)
------------------

* Add support for `as: Regexp` #132

3.4.7 (2013-11-14)
------------------

* Ensure trash is cleared on every parse so you can parse multiple
  times with the same instance (#130)

3.4.5 (2013-05-14)
------------------

* Allow specifying long options starting with numbers (#110, Peter Zotov)
* Ensure short-options still consume trailing arguments, ie `-abc foo`
  should assign `foo` to the option `c` if it expects an argument (#114).

3.4.4 (2013-03-12)
------------------

* Disable the run callback when the help option is used and `-h`
  or `--help` is passed. #106
* Ensure default `--help` option exits by default (#107, Autumn Perrault).

3.4.3 (2013-01-14)
------------------

* Ensure `parse!` removes commands and their options.

3.4.2 (2013-01-14)
------------------

* Expose the Hash commands as public API.
* Deprecated `Slop.optspec`.
* Ensure help output prints to stdout, not stderr.

3.4.1 (2013-01-13)
------------------

* Ensure options replace any existing duplicates
* Command config options now inherit config options from top level Slop.
* Command help output now adds command in usage string.

3.4.0 (2013-01-12)
------------------

* Implement new command system (#95)
* Deprecate Slop::Commands
* Ensure 'no-foo' options are not inverted when parsing '--no-foo' (#86)
* Code refactoring and simplification (Kenichi Kamiya, #84, #85)

3.3.3 (2012-08-29)
------------------

* Ensure autocreate arguments are not created as options (#77)
* Ensure options are not swallowed when using short options with argument
  included (#74)

3.3.2 (2012-06-26)
------------------

* Ensure multiple options are not executed unless they exist (#70)

3.3.1 (2012-05-31)
------------------

* Stop multiple switches from trashing arguments (Conrad Irwin, #66)

3.3.0 (2012-05-30)
------------------

* Fix `:as => :count` when using multiple switches.
* Ensure range typecast allows negative range values.
* Ignore nil objects send to #parse instead of choking.

3.2.0 (2012-05-15)
------------------

* Ensure boolean options appear correctly in `to_hash` output. (#59)

3.1.1 (2012-04-24)
------------------

* Ensure separators before any options are still being processed (#62)

3.1.0 (2012-04-23)
------------------

* Allow options to be fetched via underscores instead of dashes
  (as a fallback) (Eric Anderson, #51)
* Added `Slop#strict?` method.
* Added strict checks for Integer/Float type casting. (Amon Sha)
* Ensure separators are not replacing existing separators (#61)

3.0.4 (2012-01-31)
------------------

* Ensure `option=argument` syntax does not consume following arguments (#55).

3.0.3 (2012-01-30)
------------------

* Ensure options passed after option terminator do not raise an exception
  (#54, Amon Sha)

3.0.2 (2012-01-27)
------------------

* Ensure `--option=value` is being evaluated before multiple switches (#52)

3.0.1 (2012-01-27)
------------------

* Ensure tests run green on 1.8.7
* Ensure `:argument => :optional` works with `:option=` format.
* Ruby 1.8.7 compat fix (dont chain Enumerable methods!) (Eric Anderson)

3.0.0 (2012-01-24)
------------------

* value_to_range returns an x..x range if the value looks like an integer.
* Lots of code refactoring
* Use TomDoc documentation
* Added `Slop::Commands` and removed existing command system
* Configuration options altered:
	* `:optional` has been renamed to `:optional_argument`
	* Added `:required` for mandatory options
	* `:argument` now accepts an `:optional` symbol as well as boolean value
* Removed Slop instance methods:
	* description=, description
	* summary=, summary
	* command
	* on_empty
	* on_noopts
	* execute
	* to_struct
* Added Slop instance methods:
	* separator
	* fetch_option
	* add_callback

2.4.3 (2012-01-16)
------------------

* Allow the `:as` option to accept an object responding to :call for
  custom type conversions (#45)
* Ensure negative integers are not parsed as possible options (#46)

2.4.2 (2011-12-18)
------------------

* Fix checking of required options (Dominik Honnef)

2.4.1 (2011-12-08)
------------------

* Ensure optional arguments are returned correctly

2.4.0 (2011-11-26)
------------------

* Avoid `define_method` for checking an options presence (and caching it) #37
* Ensure the short option allows an appended `=` for accepting arguments
* Implement `respond_to?`

2.3.1 (2011-11-11)
------------------

* Return `nil` for any options using casting which don't expect arguments (#33)
* Fix parenthesis warning on 1.8.7 (@shevegen)
* Ensure long argument is a string before attempting to use `#[]` method on it

2.3.0 (2011-11-04)
------------------

* Allow flags to have suffixed `=` char for options which accept an argument

2.2.0 (2011-11-02)
------------------

* Support `bup.options` style optspec parsing
    * http://apenwarr.ca/log/?m=201111

* Allow `:as` to accept a `count` value (Conrad Irwin):

    `on :v, :verbose, :as => :count # -vv; opts[:verbose] #=> 2`

2.1.0 (2011-08-03)
------------------

* Added `Slop#missing` for returning a list of missing options parsed
* Allow `Slop#present?` to accept multiple arguments
* Added `:all_accept_arguments` to Slop configuration options, this saves
  having to specify that every option takes an argument
* Added `Slop#to_struct` for building new classes from options

2.0.0 (2011-07-07)
------------------

* Deprecations:
  * Removed `Slop::Options#to_hash` continue using `Slop#to_hash` directly.
    This method also now returns symbols by default instead of strings. If
    you want strings use `opts.to_hash(false)`
  * `:multiple_switches` is now enabled by default, to parse `fbar` as the
    option `f` with value `bar` you must disable `:multiple_switches`
  * Removed `Slop::Options#to_help` and merged its contents into `Slop#help`
  * Removed `lib/slop/options.rb` and merged `Slop::Options` into slop.rb
  * Removed `lib/slop/option.rb` and merged `Slop::Option` into slop.rb
  * These changes make Slop much easier to vendor in libraries
* `Slop::Option` now inherits from `Struct.new`
* Added Slop::Error subclassing from StandardError which all exception
  classes should inherit from
* Added Slop::MissingOptionError and `:required` option to Slop::Option.
  This exception is raised when a mandatory option is not used

1.9.1 (2011-06-16)
------------------

* Ensure optional items with no arguments still return true when searching
  for presence

1.9.0 (2011-06-15)
------------------

* Add command completion and support for an error message when ambiguous
  commands are used
* Add command aliases
* Fix: Ensure parsed elements are removed from original arguments when using
  `:multiple_switches`
* Ensure anything after `--` is parsed as an argument and not option even
  if prefixed with `/--?/`
* Performance improvements when making many calls to `Slop#option?` for
  checking an options presence (Rob Gleeson)
* Ensure `execute` passes command arguments to the block
* Support for summary and description (Denis Defreyne)

1.8.0 (2011-06-12)
------------------

* Added `execute` method to Slop for commands. This block will be invoked
  when a specific command is used. The Slop object will be yielded to the
  block
* Allow passing a class name to `on` to be used as an `:as` option. ie:
  `on :people, 'Some people', Array`
* Get smart with parsing options optparse style: `on '--name NAME'` and
  `on 'password [OPTIONAL]'`
* Feature: `:arguments` setting to enable argument passing for all options

1.7.0 (2011-06-06)
------------------

* Feature: Autocreate (auto create options at parse time, making assumptions)
* Feature: When parsing options as arrays, push multiple arguments into a
  single array

1.6.1 (2011-06-01)
------------------

* Fix tests and using a temporary Array for ARGV, fixes RubyGems Test issues
* General cleanup of code

1.6.0 (2011-05-18)
------------------

* Add `:ignore_case` to Slop options for case insensitive option matching
* Add `:on_noopts` for triggering an event when the arguments contain no
  options
* Add `:unless` to Slop::Option for omitting execution of the Options block
  when this object exists in the Array of items passed to Slop.new
* Bugfix: Do not parse negative integers as options. A valid option must
  start with an alphabet character
* Bugfix: Allow a Range to accept a negative Integer at either end

1.5.5 (2011-05-03)
------------------

* Bugfix: only attempt to extract options prefixed with `-`

1.5.4 (2011-05-01)
------------------

* Bugfix: `parse!` should not remove items with the same value as items used
  in option arguments. Fixes #22 (Utkarsh Kukreti)

1.5.3 (2011-04-22)
------------------

* Bugfix: Use integers when fetching array indexes, not strings

1.5.2 (2011-04-17)
------------------

* Bugfix: Ensure `ARGV` is empty when using the `on_empty` event

1.5.0 (2011-04-15)
------------------

* Add `Slop#get` as alias to `Slop#[]`
* Add `Slop#present?` as alias for `Slop#<option>?`
* Add `Option#count` for monitoring how many times an option is called
* Add `:io` for using a custom IO object when using the `:help` option
* Numerous performance tweaks
