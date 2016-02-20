# Cliver

Sometimes Ruby apps shell out to command-line executables, but there is no
standard way to ensure those underlying dependencies are met. Users usually
find out via a nasty stack-trace and whatever wasn't captured on stderr, or by
the odd behavior exposed by a version mismatch.

`Cliver` is a simple gem that provides an easy way to detect and use
command-line dependencies. Under the covers, it uses [rubygems/requirements][]
so it supports the version requirements you're used to providing in your
gemspec.

## Usage

### Detect and Detect!

The detect methods search your entire path until they find a matching executable
or run out of places to look.

```ruby
# no version requirements
Cliver.detect('subl')
# => '/Users/yaauie/.bin/subl'

# one version requirement
Cliver.detect('bzip2', '~> 1.0.6')
# => '/usr/bin/bzip2'

# many version requirements
Cliver.detect('racc', '>= 1.0', '< 1.4.9')
# => '/Users/yaauie/.rbenv/versions/1.9.3-p194/bin/racc'

# dependency not met
Cliver.detect('racc', '~> 10.4.9')
# => nil

# detect! raises Cliver::Dependency::NotMet exceptions when the dependency
# cannot be met.
Cliver.detect!('ruby', '1.8.5')
#  Cliver::Dependency::VersionMismatch
#    Could not find an executable ruby that matched the
#    requirements '1.8.5'. Found versions were {'/usr/bin/ruby'=> '1.8.7'}
Cliver.detect!('asdfasdf')
#  Cliver::Dependency::NotFound
#    Could not find an executable asdfasdf on your path
```

### Assert

The assert method is useful when you do not have control over how the
dependency is shelled-out to and require that the first matching executable on
your path satisfies your version requirements. It is the equivalent of the
detect! method with `strict: true` option.

## Advanced Usage:

### Version Detectors

Some programs don't provide nice 'version 1.2.3' strings in their `--version`
output; `Cliver` lets you provide your own version detector with a pattern.

```ruby
Cliver.assert('python', '~> 1.7',
              detector: /(?<=Python )[0-9][.0-9a-z]+/)
```

Other programs don't provide a standard `--version`; `Cliver::Detector` also
allows you to provide your own arg to get the version:

```ruby
# single-argument command
Cliver.assert('janky', '~> 10.1.alpha',
              detector: '--release-version')

# multi-argument command
Cliver.detect('ruby', '~> 1.8.7',
              detector: [['-e', 'puts RUBY_VERSION']])
```

You can use both custom pattern and custom command by supplying an array:

```ruby
Cliver.assert('janky', '~> 10.1.alpha',
              detector: ['--release-version', /.*/])
```

And even supply multiple arguments in an Array, too:

```ruby
# multi-argument command
Cliver.detect('ruby', '~> 1.8.7',
              detector: ['-e', 'puts RUBY_VERSION'])
```

Alternatively, you can supply your own detector (anything that responds to
`#to_proc`) in the options hash or as a block, so long as it returns a
`Gem::Version`-parsable version number; if it returns nil or false when
version requirements are given, a descriptive `ArgumentError` is raised.

```ruby
Cliver.assert('oddball', '~> 10.1.alpha') do |oddball_path|
  File.read(File.expand_path('../VERSION', oddball_path)).chomp
end
```

And since some programs don't always spit out nice semver-friendly version
numbers at all, a filter proc can be supplied to clean it up. Note how the
filter is applied to both your requirements and the executable's output:

### Filters

```ruby
Cliver.assert('built-thing', '~> 2013.4r8273',
              filter: proc { |ver| ver.tr('r','.') })
```

Since `Cliver` uses `Gem::Requirement` for version comparrisons, it obeys all
the same rules including pre-release semantics.

### Search Path

By default, Cliver uses `ENV['PATH']` as its search path, but you can provide
your own. If the asterisk symbol (`*`) is included in your string, it is
replaced `ENV['PATH']`.

```ruby
Cliver.detect('gadget', path: './bins/:*')
# => 'Users/yaauie/src/project-a/bins/gadget'
```

## Supported Platforms

The goal is to have full support for all platforms running ruby >= 1.9.2,
including rubinius and jruby implementations, as well as basic support for
legacy ruby 1.8.7. Windows has support in the codebase,
but is not available as a build target in [travis_ci][].

## See Also:

 - [YARD Documentation][yard-docs]
 - [Contributing](CONTRIBUTING.md)
 - [License](LICENSE.txt)


[rubygems/requirements]: https://github.com/rubygems/rubygems/blob/master/lib/rubygems/requirement.rb
[yard-docs]: http://yaauie.github.io/cliver/
[travis-ci]: https://travis-ci.org/yaauie/cliver
