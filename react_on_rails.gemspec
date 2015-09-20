# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'react_on_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "react_on_rails"
  spec.version       = ReactOnRails::VERSION
  spec.authors       = ["Justin Gordon"]
  spec.email         = ["justin@shakacode.com"]

  spec.summary       = %q{Rails with react server rendering with webpack. }
  spec.description   = %q{See README.md}
  spec.homepage      = "https://github.com/shakacode/react_on_rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 4.2"
  spec.add_dependency "execjs", "~> 2.5"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "coveralls"
end
