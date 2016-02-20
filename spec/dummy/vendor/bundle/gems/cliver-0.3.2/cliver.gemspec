# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cliver/version'

Gem::Specification.new do |spec|
  RUBY_18 = RUBY_VERSION[/\A1\.8\..*/]
  spec.name          = 'cliver'
  spec.version       = Cliver::VERSION
  spec.authors       = ['Ryan Biesemeyer']
  spec.email         = ['ryan@yaauie.com']
  spec.description   = 'Assertions for command-line dependencies'
  spec.summary       = 'Cross-platform version constraints for cli tools'
  spec.homepage      = 'https://www.github.com/yaauie/cliver'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']
  spec.has_rdoc      = 'yard'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'ruby-appraiser-reek'    unless RUBY_18
  spec.add_development_dependency 'ruby-appraiser-rubocop' unless RUBY_18
  spec.add_development_dependency 'yard'
end
