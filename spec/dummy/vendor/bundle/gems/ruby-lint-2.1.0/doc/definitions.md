# @title Definitions
# Definitions

To obtain extra information used in the analysis process ruby-lint uses a set
of so called "definitions". These definitions describe constants and their
methods and the associated arguments of said methods. The definitions can be
created using a basic DSL. Typically end users don't have to write these
manually as ruby-lint comes with a set of Rake tasks to ease the process of
creating these definitions. However, manual tweaking might be required in rare
cases.

## Rationale

The definitions exist for 3 reasons:

1. Both MRI and JRuby provide insufficient runtime reflection on method
   arguments (more on this below), a rather crucial aspect in performing
   meaningful analysis.
2. Relying on the current runtime for extra information means that users will
   have to load all their used libraries into a ruby-lint session. This will
   often result in degraded performance, in particular startup times will
   increase.
3. It's not possible to, during runtime, determine the return type(s) of a
   method. This can only be done by either relying on source documentation or
   by other manual means.

These 3 topics are described in detail below.

### Argument Reflection

Ruby as a language provides the means to, during runtime, find out what
arguments a method has, their types and names. For example, consider the
following code:

    def example(a, b)
      return a + b
    end

We can obtain the arguments list by running the following code:

    method(:example).parameters

This would result in the following value being returned:

    [[:req, :a], [:req, :b]]

Using this we can see that the method takes two required arguments, `a` and
`b`.

Although this works great for methods that are defined in Ruby itself this does
not work reliably for methods defined in C (in case of MRI) or in Java (in case
of JRuby).

As an example, lets take a look at `String#gsub`. The RDoc documentation of
this method states the following about its arguments:

    = String#gsub

    (from ruby core)
    ------------------------------------------------------------------------------
      str.gsub(pattern, replacement)       -> new_str
      str.gsub(pattern, hash)              -> new_str
      str.gsub(pattern) {|match| block }   -> new_str
      str.gsub(pattern)                    -> enumerator

This states that the method takes 1 required argument (`pattern`), one optional
argument (`replacement` / `hash`) and a block. However, when we inspect the
arguments list of this method in MRI we get different results:

    String.instance_method(:gsub).parameters # => [[:rest]]

This would indicate that the method instead takes a single rest argument. This
however is simply false as calling the method without any arguments (rest
arguments being optional) results in an argument error:

    'foo'.gsub # => ArgumentError: wrong number of arguments (0 for 1..2)

This is due to the fact that `String#gsub` method (and many other methods in
MRI) are defined in C. Since the C API doesn't expose proper systems for
exposing the argument amounts/types this information is lost.

JRuby is also affected by this though at present it's unclear to me if this is
intentional (in order to mimic MRI's broken behaviour) or a side effect.
Currently Rubinius is the only Ruby implementation that I know of that does not
suffer from this problem, largely due to it actually using Ruby for a large
amount of its core.

The above problem also affects every Ruby C extension such as Nokogiri and many
others.

This particular lack of information is problematic for ruby-lint as it means
that it can not perform meaningful analysis when it relies on the current
runtime. After all, the accuracy of the analysis process would change depending
on the Ruby implementation leading to confusing behaviour and false positives.

To combat this ruby-lint doesn't use the current runtime for obtaining method
information. Instead it uses definitions that are pre-generated using Rubinius.
However, even on Rubinius the accuracy of these definitions will vary for C
extensions depending on how much these extensions define in C opposed to Ruby.

### Degraded Performance

The second reason for not using the current runtime is that by doing so users
would be required to load their libraries into a ruby-lint session. For
example, for a Rails project this means loading all of Rails, all the used
Gems, custom code defined in the `app/` directory and so forth. Doing so will
increase the startup time of ruby-lint up to a point where it becomes downright
annoying.

To give an example, merely loading Rails using `require 'rails/all'` will add
around 500 milliseconds to the startup time. Add a few more Gems such as
Devise, Mongoid and what not and you'll quickly end up having to wait seconds
for ruby-lint to start up (or any other Ruby program for that matter).

As a result of this it was decided that this was less than optimal, which in
turn was another reason to use pre-generated definitions.

### Return Types

Due to Ruby being dynamically typed it's impossible to deduce the return type
of a method. As a result of this ruby-lint would not be able to figure out what
`SomeClass.new` would return. This means that for code such as
`SomeClass.new.foo` ruby-lint would have no other choice but to completely
ignore it.

ruby-lint tries to work around this using two methods:

1. Using YARD documentation (in particular the `@return` and `@param` tags) to
   obtain more information during runtime.
2. Using pre-generated definitions that specify return types such as those for
   the `new` and `initialize` methods.

This means that ruby-lint is capable of understanding that `String.new` returns
an instance of `String`. ruby-lint makes the assumption that the class method
`new` returns an instance of the constant it is defined in, unless the method
is explicitly overwritten.

## Generating Definitions

In most cases one does not need to write these definitions manually, instead
they are generated using a set of Rake tasks. For best results it's recommended
to use Rubinius in case you're generating definitions for the Ruby standard
library.

Assuming you have a local copy of ruby-lint you can generate your definitions
by running the following Rake task:

    rake -r YOUR_GEM generate:definitions[CONSTANT,lib/ruby-lint/definitions/gems]

Here `YOUR_GEM` would be the name of your Gem, `CONSTANT` would be the
top-level constant. For example, to generate the definitions for Devise you'd
run the following:

    rake -r devise generate:definitions[Devise,lib/ruby-lint/definitions/gems]

If you are comfortable with the resulting definitions you can submit a pull
request and I'll take a look at it. I prefer for the definitions to be included
with ruby-lint itself as this makes it easier to maintain and distribute them
without requiring users to install a bunch of extra Gems.

## Using Definitions

When processing source code ruby-lint will try to automatically load
definitions where needed. For this to work the definitions should be available
in the load path defined in {RubyLint::Definition::Registry#load\_path}. By
default the following directories are searched in for definitions:

* lib/ruby-lint/definitions/core
* lib/ruby-lint/definitions/rails
* lib/ruby-lint/definitions/gems

There should be no need to add extra paths to this list.

Definitions are looked up based on the top-level constant referenced in a file.
For example, of ruby-lint bumps into the constant path `Foo::Bar::Baz` it will
try to look for a file called `foo.rb` in the above directories. It is expected
that if this file exists it defines the `Foo` constant (and its child
constants).

The process of loading definitions is handled by
{RubyLint::Definition::Registry#load} and
{RubyLint::ConstantLoader#load\_constant}.
