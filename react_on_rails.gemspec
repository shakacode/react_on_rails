# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'react_on_rails/version'

Gem::Specification.new do |s|
  s.name          = "react_on_rails"
  s.version       = ReactOnRails::VERSION
  s.authors       = ["Justin Gordon"]
  s.email         = ["justin@shakacode.com"]

  s.summary       = %q{Rails with react server rendering with webpack. }
  s.description   = %q{See README.md}
  s.homepage      = "https://github.com/shakacode/react_on_rails"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|tmp|node_modules|node_package|coverage)/}) }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "connection_pool"
  s.add_dependency "execjs", "~> 2.5"
  s.add_dependency "rainbow", "~> 2.0"
  s.add_dependency "rails", ">= 3.2"

  s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "generator_spec"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "pry-stack_explorer"
  s.add_development_dependency "pry-doc"
  s.add_development_dependency "pry-state"
  s.add_development_dependency "pry-toys"
  s.add_development_dependency "pry-rescue"
  s.add_development_dependency "binding_of_caller"
  s.add_development_dependency "awesome_print"
end
