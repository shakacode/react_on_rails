# @title Changelog
# Changelog

This document contains a short summary of the various releases of ruby-lint.
For a full list of commits included in each release see the corresponding Git
tags (named after the versions).

## 2.1.0 - 2016-01-22

Ryan McKern added a definition for `Module#module_function` in pull request
<https://github.com/YorickPeterse/ruby-lint/pull/162>.

## 2.0.5 - 2015-09-14

* When reading files to analyse the encoding is explicitly set to UTF8,
  see commit 78eab2a79ae4b66e365b14062d0b7dd64fb1ad04 for more information.
  Thanks to Carsten Bormann for adding this.
* The license was changed from MIT to MPL 2.0, see commit
  f1c3aa396c815b42524cfaab5e2abdd74d5bd081 for more information.

## 2.0.4 - 2015-04-15

Definitions were added for test-unit to take care of
<https://github.com/YorickPeterse/ruby-lint/issues/142>.

## 2.0.3 - 2015-01-09

* ruby-lint now adds errors for certain iteration/loop keywords that are used
  outside of loops. See <http://git.io/dsVzhA> for more information.
* The FileScanner was modified to allow it to process directories containing
  dashes, see <http://git.io/eNiq9A> for more information.
* Definitions for Mongoid, Sinatra, win32ole, glib2, gtk3, libxml, RubyTree, and
  the ALM REST API were added.
* Usage of `Array#|` has been replaced with `Array#+` in
  `RubyObject#determine_parent`, leading to a small performance boost, see
  <http://git.io/1SIguw> for more information.

## 2.0.2 - 2014-08-05

* Definitions for Celluloid have been added.
* The definitions for `Math` have been updated to include constants such as
  `Math::PI`
* The definitions for `Digest` have been updated so that `hexdigest` is
  processed correctly.
* Users can now specify a custom configuration file using the `-c` and/or
  `--config` option. See <https://github.com/YorickPeterse/ruby-lint/issues/124>
  for more information.

## 2.0.1 - 2014-06-11

* The exit status of ruby-lint is set to 1 when there is data to report. See
  <https://github.com/YorickPeterse/ruby-lint/issues/117> for more info.

## 2.0.0 - 2014-06-06

Although the version number might suggest otherwise this is a rather modest
release compared to previous releases.

There are 3 big changes in this release:

1. A refactored and less confusing CLI.
2. The caching system has been removed as it was too problematic.
3. The API used for registering analysis classes has been changed to make it
   easier to register custom classes.

The first change is not backwards compatible with previous releases of
ruby-lint, hence the mayor version increase.

The following other changes are included in this release:

* Fuzzy file matching when scanning for external files has been removed. This
  was too problematic and would cause problems such as
  <https://github.com/YorickPeterse/ruby-lint/issues/105>.
* Definitions for Minitest have been added.
* Proper handling of methods called on block return values.
* Constant paths with variables in them are handled properly.
* Diagnostics emitted by the parser Gem are re-used properly by ruby-lint
  instead of always being displayed as errors.
* ARGF is handled with extra care so that ruby-lint doesn't throw tons of false
  positives.
* Debug output has been removed from the CLI, it will be replaced with a better
  system in the near future.

## 1.1.0 - 2014-02-02

This release changes the way the definitions system works so that it no longer
stores a set of global definition objects. Instead "templates" (so to speak)
are provided which are applied to individual `RubyLint::VirtualMachine`
instances. This makes it much easier to analyze code that patches core classes
such as `String` or `Fixnum`.

There have also been various other, smaller changes. The ones worth mentioning
as following:

* A new analysis class, UselessEqualityChecks, has been added. This class adds
  warnings for expressions such as `"foo" == true`.
* A Rake task class has been added, making it easier to integrate ruby-lint in
  a Rakefile.
* The CLI has been cleaned up and the `plot` and `ast` commands have been
  removed. A new command, `cache` has been introduced to manage ruby-lint cache
  files more easily.
* A bug has been fixed that would prevent ruby-lint from properly loading files
  from multiple directories, see Git commit
  `292bb2b73aa6adfdc750fb846884025afc841393`.
* Definitions have been added for Devise and Nokogiri.
* Most built-in definitions have been re-generated.
* Definitions system has been overhauled to no longer use a global state and a
  complex data copying system. Instead the definitions are applied to every
  individual `RubyLint::VirtualMachine` instance.
* Updated the version of the parser Gem to use.

The following bugs/issues have been resolved in this release:

* https://github.com/YorickPeterse/ruby-lint/issues/89
* https://github.com/YorickPeterse/ruby-lint/issues/85
* https://github.com/YorickPeterse/ruby-lint/issues/91
* https://github.com/YorickPeterse/ruby-lint/issues/92
* https://github.com/YorickPeterse/ruby-lint/issues/93
* https://github.com/YorickPeterse/ruby-lint/issues/94
* https://github.com/YorickPeterse/ruby-lint/issues/100
* https://github.com/YorickPeterse/ruby-lint/issues/101
* https://github.com/YorickPeterse/ruby-lint/issues/102

## 1.0.3 - 2013-12-23

* `self` is now defined as a class and instance method to ensure that the right
  data is used in these two scopes. See
  `28f604ded884be2e43ef7ce93892a3cade4c93d7` for a more in depth explanation.
* Block arguments passed to methods are now ignored by the `ArgumentAmount`
  analysis class.
* Configuration objects are now passed to analysis classes.
* ruby-lint can now parse empty Ruby files! Previously this would crash the
  parser.
* Range now inherits from Enumerable.
* The definitions for Array have been re-generated.
* Fix for searching for Ruby files when no directories were given to the file
  scanner class. Previously this would cause ruby-lint to start scanning from
  `/`. See <https://github.com/YorickPeterse/ruby-lint/issues/83> for more
  information.

## 1.0.2 - 2013-12-19

This release changes the default file scanner directories from `$PWD` to
`$PWD/app` and `$PWD/lib` as the former proved to be too much trouble. This
release also changes the pre-globbing of the file scanner so that it only
starts looking for files when actually needed.

## 1.0.1 - 2013-12-15

A small bugfix release that contains the following changes/fixes:

* Anonymous splat arguments (`def foo(_); end`) are now ignored by the
  `UnusedVariables` class.
* Frozen definitions no longer have their members updated, see
  <https://github.com/YorickPeterse/ruby-lint/issues/75> for more information.
* ENV is now treated as an instance.
* When re-assigning a variable the VM now updates the corresponding definition
  instead of overwriting it. This was added to fix
  <https://github.com/YorickPeterse/ruby-lint/issues/77>.
* Global variables are stored in the global scope opposed to the current scope.
* ARGV is now treated as an instance and extends Array.

## 1.0.0 - 2013-12-01

The first stable release of ruby-lint. The 1.0 series will not introduce any
breaking API changes. The changes in this particular release are fairly small.
Initially I wanted to include the ability to skip analysis for certain
constants but I've decided to hold this off until the next release as I'm not
yet sure how I envision this feature.

Having said that, this release contains the following noteworthy changes:

* Column numbers now start from 1 instead of 0, something I completely
  overlooked until now.
* Performance of `RubyLint::FileScanner#scan` has been improved significantly
  (more on this below).
* ruby-lint can now run analysis on an entire directory instead of only
  operating on individual files.
* Support for Range instances when building definitions.
* Various extra stdlib definitions have been added.
* Support for conditional code analysis (see below).

### FileScanner Performance

The performance of `RubyLint::FileScanner#scan` has been improved
significantly. In previous versions a call to `Dir.glob` was made every time
ruby-lint tried to find a constant from the local file system. This process has
been improved by retrieving all Ruby files at once and caching the results.
When performing analysis on `lib/ruby-lint/virtual_machine.rb` this change lead
to a reduction in execution time of about 400 milliseconds.

See <http://git.io/Q5s8Lw> for a more detailed description of this change.

### Conditional Code Analysis

This new feature allows analysis classes themselves to determine whether or not
they should be used. This can be used to write analysis code that only runs on
Rspec files for example.

Currently ruby-lint doesn't ship with any analysis classes that use this
feature but I plan to add these in the future.

## 0.9.1 - 2013-10-21

A small release that only includes 3 changes:

1. A presenter specifically designed for [Syntastic][syntastic]
2. STDOUT/STDERR/STDIN definitions are now treated as instances meaning method
   calls such as `reopen` are processed correctly.
3. ruby-lint now enforces the use of the latest Racc version as this version
   contains various performance improvements that are especially noticeable on
   Rubinius.

The Syntastic presenter is the most important addition as it allows me to
finally publish my Syntastic plugin without having to use various Vim hacks to
make it properly consume ruby-lint output.

## 0.9.0 - 2013-10-13

Although the version number increased by quite a bit this release in itself is
fairly small. Seeing how the ruby-lint internals are slowly becoming more and
more stable I'd like the version numbers to correspond with that. I'm not
jumping to 1.0 right away since I do want to make various changes to the
internals before I release 1.0.

Having said that, this release contains the following:

* Caching of ASTs required for finding externally defined constants.
* An extra CLI command (`plot`) for plotting analysis timings.
* Method call tracking.
* Warnings for unused method/block arguments.
* Support for Rubinius 2.0.

The two most noteworthy changes are the caching system and support for method
call tracking, these are highlighted below.

### Caching

In previous releases ruby-lint would re-parse extra files needed (those that
contain the definitions of referenced constants) every time you'd analyze a
file. This was rather problematic since [parser][parser] sadly isn't the
fastest kid on the block. By caching the resulting ASTs performance of the same
file (assuming it doesn't change between runs) can be increased drastically. If
the analyzed file or an external one is changed the cache is invalidated
automatically.

Caching is enabled by default so you don't need to add any extra command-line
flags or configuration options in your ruby-lint configuration file.

### Method Call Tracking

This new features makes it possible for ruby-lint to keep track of what methods
are called from another method, both in the direction of caller to callee and
the other way around. Currently this isn't used yet for any analysis but I have
some ideas on adding useful analysis using this new feature. Another use case
for this feature is generating Graphviz call graphs without actually having to
run the corresponding Ruby source code.

## 0.0.5 - 2013-09-01

Originally slated for August 1st I decided to push this release back one month
to buy myself some extra time to polish features, resolve more bugs and
procrastinate more. Besides numerous bug fixes and extra polish this release
contains two big new features that I'd like to highlight:

* support for parsing basic YARD tags
* loading of externally defined constants/files from the local file system

### YARD Support

[YARD][yard] provides a set of tags that can aid in documenting your code. For
example, `@param` is a tag used to document the type, name and description of a
method parameter. Since Ruby has no form of type hinting you're often left to
wonder what kind of objects a method can work with.

In version 0.0.5 support for two tags was added:

* `@param`
* `@return`

When ruby-lint finds methods documented using these tags it will use them to
pull in information about the parameter types and return values. This greatly
increases the accuracy of ruby-lint, given your code is documented. Consider
the following example:

    def multiply(value, multiplier)
      return value * value
    end

If ruby-lint were to process the above code it would have no idea what kind of
object `value` and `multiplier` are and thus wouldn't be able to much with the
above code. When documenting the above method with the mentioned YARD tags
ruby-lint *is* capable of doing this:

    ##
    # @param [Fixnum] value
    # @param [Fixnum] multiplier
    # @return [Fixnum]
    #
    def multiply(value, multiplier)
      return value * value
    end

By parsing the YARD tags ruby-lint can now know what the parameter types are
and what type of data the method returns. This in turn allows ruby-lint to
perform full analysis on the arguments instead of being forced to ignore them
completely.

### Loading External Files

In previous versions ruby-lint had no way of loading external code that was not
pre-defined using the built-in definitions (found in
`lib/ruby-lint/definitions`). As a result a lot of false positives would be
triggered when analysing complex projects (e.g. the typical Rails project).

This has been addressed by introducing so called "file scanners" and "file
loaders". In short, these scan for a set of constants used in a file and try to
find the corresponding Ruby file that defines it (recursively). This greatly
enhances the accuracy of analysis.

Currently the algorithm for this is rather basic and can, especially in big
projects, slow analysis down by quite a bit. This will be resolved in upcoming
releases. Keep an eye on the following issues for more information:

* <https://github.com/YorickPeterse/ruby-lint/issues/50>
* <https://github.com/YorickPeterse/ruby-lint/issues/49>

### Other Changes

Besides the two features mentioned above various other changes have also been
made, these are listed below.

* Lots of bug fixes and cleanups, as you'd expect.
* Constants (classes and modules) can now be referred by their name inside
  themselves (e.g. "Foo" inside the class "Foo" refers to that class).
* The text presenter now only shows filenames instead of the full file path,
  reducing clutter.
* Support for default global variables such as `$LOADED_FEATURES`
* Support for methods such as `alias` and `alias_method`
* Support for the `attr_*` family of methods
* The test suite has been migrated from Bacon to RSpec
* Support for keyword arguments.
* Updated built-in Rails definitions to include more methods.
* Debugging/benchmarking output for the analyze command.
* The analysis class ConfusingVariables has been removed due to not being very
  useful.
* Various issues with method lookups inside blocks have been resolved.
* Various internals have been cleaned up.
* Improved error messages for calls to undefined methods.

## 0.0.4 - 2013-07-14

Near total refactor of the entire project. New parser setup based on the
"parser" Gem instead of using a custom built parser built using Ripper. More
analysis classes, a more stable mechanism for building definitions, bug fixes
and a lot more.

This release (thanks to "parser") also introduces support for Jruby and
Rubinius (2.0/Git HEAD, 1.X is not supported).

## 0.0.3 - 2013-04-22

Lots of internal changes for tasks such as building definitions. Also included
a large set of bugfixes.

## 0.0.2 - 2012-11-15

Various changes to the old parser.

## 0.0.1 - 2012-11-13

First public release of ruby-lint.

[yard]: http://yardoc.org/
[parser]: https://github.com/whitequark/parser
[syntastic]: https://github.com/scrooloose/syntastic
