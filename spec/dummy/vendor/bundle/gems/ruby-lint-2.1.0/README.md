# ruby-lint

ruby-lint is a static code analysis tool for Ruby. It is inspired by tools such
as jshint, flake8 and similar tools. ruby-lint primarily focuses on logic
related errors such as the use of non existing variables instead of focusing on
semantics (e.g. the amount of characters per line).

The features of ruby-lint include but are not limited to the detection of
unused variables, the use of undefined methods and method calls with invalid
argument amounts and more. More in-depth analysis will be added over time.

The aim of ruby-lint is to provide analysis that is as accurate as possible.
However, due to the dynamic nature of Ruby and the sheer amount of meta-magic
in third-party code there will at times be false positives. Analysis can be
improved by documenting your code using [YARD][yard], in particular the
`@param` and `@return` tags are used by ruby-lint to obtain extra information
when processing methods.

## Requirements

* a Ruby implementation running 1.9 or newer
* a Unix based Operating System

The following Ruby implementations/versions are officially supported:

* MRI 1.9.3, 2.0 or 2.1
* Rubinius 2.0 and newer
* Jruby 1.7 and newer

Ruby implementations running a 1.8 based version of Ruby are not supported.

## Installation

The easiest way to install ruby-lint is to install it from RubyGems:

    gem install ruby-lint

If you prefer to install (and build) ruby-lint from the source code you can do
so as following:

    git clone git://github.com/YorickPeterse/ruby-lint.git
    cd ruby-lint
    bundle install # you can also install the dependencies manually
    rake build

This builds a new version of the Gem and saves it in the pkg/ directory.

## Usage

Using ruby-lint from the CLI is very easy. To analyze a set of files
you run the following:

    ruby-lint file1.rb file2.rb

For more information specify either the `-h` or `--help` option.

## Example

Given the following code:

    class Person
      def initialize(name)
        # oops, not setting @name
      end

      def greet
        return "Hello, #{@name}"
      end
    end

    user     = Person.new('Alice')
    greeting = user.greet

    user.greet(:foo)

Analysing this file using ruby-lint (with the default settings) would result in
the following output:

    test.rb: error: line 7, column 22: undefined instance variable @name
    test.rb: warning: line 12, column 1: unused local variable greeting
    test.rb: error: line 14, column 1: wrong number of arguments (expected 0 but got 1)

## ruby-lint versus RuboCop

A question commonly asked is what purpose ruby-lint serves compared to other
tools such as [RuboCop][rubocop]. After all, upon first sight the two tools
look pretty similar.

The big difference between ruby-lint and RuboCop is that ruby-lint focuses
primarily on technical problems such as the use of undefined methods/variables,
unused variables/method arguments and more. RuboCop on the other hand focuses
mostly on style related issues based on a community driven Ruby style guide.
This means that it will for example warn you about methods written using
camelCase and method bodies that are considered to be too long.

Personally I have little interest in adding style related analysis as RuboCop
already does that and in my opinion does a far better job at it. I also simply
think it's too boring to write analysis like this. Having said that, ruby-lint
has some basic style related analysis (e.g. the use of `BEGIN`) but this mostly
serves as a simple example on how to write analysis code.

In the end it depends on what your needs are. If you have a team that's having
trouble following a consistent coding style then RuboCop is probably the right
tool for the job. On the other hand, if you're trying to debug a nasty bug then
ruby-lint will most likely be more useful.

## Security

As a basic form of security ruby-lint provides a set of SHA512 checksums for
every Gem release. These checksums can be found in the `checksum/` directory.
Although these checksums do not prevent malicious users from tampering with a
built Gem they can be used for basic integrity verification purposes.

The checksum of a file can be checked using the `sha512sum` command. For
example:

    $ sha512sum pkg/ruby-lint-0.9.1.gem
    10a51f27c455e5743fff7fefe29512cff20116b805bec148e09d4bade1727e3beab7f7f9ee97b020d290773edcb7bd1685858ccad0bbd1a35cc0282c00c760c6  pkg/ruby-lint-0.9.1.gem

In the past Gems were also signed using PGP, this is no longer the case.

## Documentation

* {file:CONTRIBUTING Contributing}
* {file:architecture Architecture}
* {file:code\_analysis Code Analysis}
* {file:configuration Configuration}
* {file:definitions Definitions}

## License

All source code in this repository is subject to the terms of the Mozilla Public
License, version 2.0 unless stated otherwise. A copy of this license can be
found the file "LICENSE" or at <https://www.mozilla.org/MPL/2.0/>.

[rubocop]: https://github.com/bbatsov/rubocop
[yard]: http://yardoc.org/
