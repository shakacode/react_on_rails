# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "react_on_rails/version"

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |s|
  s.name          = "react_on_rails"
  s.version       = ReactOnRails::VERSION
  s.authors       = ["Justin Gordon"]
  s.email         = ["justin@shakacode.com"]

  s.summary       = "Rails with react server rendering with webpack. "
  s.description   = "See README.md"
  s.homepage      = "https://github.com/shakacode/react_on_rails"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|gen-examples|tmp|node_modules|node_package|coverage)/})
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.1.0"

  s.add_dependency "addressable"
  s.add_dependency "connection_pool"
  s.add_dependency "execjs", "~> 2.5"
  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "rainbow", "~> 3.0"

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "bundler", "~> 1"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "gem-release"
  s.add_development_dependency "generator_spec"
  s.add_development_dependency "listen"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "pry-doc"
  s.add_development_dependency "pry-rescue"
  s.add_development_dependency "pry-stack_explorer"
  s.add_development_dependency "pry-state"
  s.add_development_dependency "pry-toys"
  s.add_development_dependency "rails", "~> 5.2"

  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rubocop", "0.55.0"

  s.post_install_message = '
--------------------------------------------------------------------------------
Email contact@shakacode.com for access to our slack room and information about our "pro support plan"
which supports better performance, via caching helpers and our node rendering server.
--------------------------------------------------------------------------------
'
end
# rubocop:enable Metrics/BlockLength
