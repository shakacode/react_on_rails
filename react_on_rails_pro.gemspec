# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "react_on_rails_pro/version"

Gem::Specification.new do |s|
  s.name          = "react_on_rails_pro"
  s.version       = ReactOnRailsPro::VERSION
  s.authors       = ["Justin Gordon"]
  s.email         = ["justin@shakacode.com"]

  s.summary       = "Rails with react server rendering with webpack. Performance helpers"
  s.description   = "See README.md"
  s.homepage      = "https://github.com/shakacode/react_on_rails_pro"
  s.metadata["rubygems_mfa_required"] = "true"

  s.files         = `git ls-files -z`.split("\x0")
                                     .reject { |f|
                                       f.match(
                                         %r{^(test|spec|features|tmp|node_modules|packages|coverage|Gemfile.lock)/}
                                       )
                                     }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.0"

  s.add_runtime_dependency "addressable"
  s.add_runtime_dependency "connection_pool"
  s.add_runtime_dependency "execjs", "~> 2.9"
  s.add_runtime_dependency "httpx", "~> 1.3", ">= 1.3.3"
  s.add_runtime_dependency "rainbow"
  s.add_runtime_dependency "react_on_rails", ">= 15.0.0.alpha.1"
  s.add_development_dependency "bundler"
  s.add_development_dependency "commonmarker"
  s.add_development_dependency "gem-release"
  s.add_development_dependency "yard"
end
