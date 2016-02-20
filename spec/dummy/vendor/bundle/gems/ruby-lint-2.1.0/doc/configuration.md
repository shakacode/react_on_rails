# @title Configuration
# Configuration

The default configuration of ruby-lint should be suitable for most people.
However, depending on your code base you may get an usual amount of false
positives. In particular the class {RubyLint::Analysis::UndefinedMethods} can
produce a lot of false positives.

ruby-lint allows developers to customize the various parts of the tool such as
what kind of messages to report and what types of analysis to run. This can be
done in two different ways:

1. Using CLI options
2. Using a configuration file

The first option is useful if you want to change something only once or if
you're messing around with the various options. If you actually want your
changes to stick around you'll want to use a configuration file instead.

## File Locations

When running the CLI ruby-lint will try to load one of the following two
configuration files:

* $PWD/ruby-lint.yml
* $HOME/.ruby-lint.yml

Here `$PWD` refers to the current working directory and `$HOME` to the user's
home directory. If ruby-lint finds a configuration file in the current working
directory the global one will *not* be loaded. This allows you to use project
specific settings in combination with a global configuration file as a
fallback.

## Configuring ruby-lint

Configuration files are simple YAML files. An example of such a configuration
file is the following:

    ---
    directories:
      - lib

    ignore_paths:
      - lib/ruby-lint/definitions
      - lib/ruby-lint/cli

### requires

The `requires` option can be used to specify a list of Ruby files that should
be loaded before analysis is performed. The primary use case of this option is
to load extra definitions that don't come with ruby-lint by default.

Example:

    ---
    requires:
      - ruby-lint/definitions/gems/devise

By default this option is left empty. You do not need to use this option for
loading built-in definitions unless stated otherwise. For example, definitions
for Rails are loaded automatically.

### report_levels

The `report_levels` option can be used to specify a list of the enabled
reporting levels. The following levels are currently available:

* info
* warning
* error

By default all of these are enabled.

Example:

    ---
    report_levels:
      - warning
      - error

### presenter

The short, human readable name of the presenter to use for displaying the
analysis results. The following presenters are currently available:

* text
* json
* syntastic

The default presenter is `text`.

Example:

    ---
    presenter: text

### analysis_classes

A list of the short, human readable names of the analysis classes to enable.
The following analysis classes are currently available:

* `argument_amount`
* `pedantics`
* `shadowing_variables`
* `undefined_methods`
* `undefined_variables`
* `unused_variables`
* `useless_equality_checks`

By default all of these are enabled.

Example:

    ---
    analysis_classes:
      - argument_amount
      - pedantics

### directories

A list of directories to search in for externally defined constants. By default
this is set to `$PWD/app` and `$PWD/lib` (depending on which directories
exist). For most applications you do not need to change this value.

Example:

    ---
    directories:
      - app
      - lib

### ignore_paths

A list of patterns to apply to the `directories` option to filter out unwanted
directories. For example, you could use this to search for files in the lib/
directory but exclude lib/foo/bar:

    ---
    directories:
      - lib

    ignore_paths:
      - lib/foo/bar

Example:

    ---
    ignore_paths:
      - lib/ruby-lint/definitions
