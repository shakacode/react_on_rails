# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "react_on_rails_pro/version"

# Load the core react_on_rails version for dependency
# This is evaluated at build time, not on user machines
require_relative "lib/react_on_rails/version"

Gem::Specification.new do |s|
  s.name          = "react_on_rails_pro"
  s.version       = ReactOnRailsPro::VERSION
  s.authors       = ["Justin Gordon"]
  s.email         = ["justin@shakacode.com"]

  s.summary       = "Rails with react server rendering with webpack. Performance helpers"
  s.description   = "See README.md"
  s.homepage      = "https://github.com/shakacode/react_on_rails_pro"
  s.license       = "UNLICENSED"
  s.metadata["rubygems_mfa_required"] = "true"

  # Explicitly whitelist Pro files to ensure we only include what belongs in this gem
  s.files         = Dir.glob("{lib/react_on_rails_pro.rb,lib/react_on_rails_pro/**/*}") +
                    Dir.glob("lib/tasks/{assets_pro.rake,v8_log_processor.rake}") +
                    %w[
                      react_on_rails_pro.gemspec
                      CHANGELOG_PRO.md
                      LICENSE
                      README.md
                    ].select { |f| File.exist?(f) }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.0"

  s.add_runtime_dependency "addressable"
  s.add_runtime_dependency "connection_pool"
  s.add_runtime_dependency "execjs", "~> 2.9"
  s.add_runtime_dependency "httpx", "~> 1.5"
  s.add_runtime_dependency "jwt", "~> 2.7"
  s.add_runtime_dependency "async", ">= 2.6"
  s.add_runtime_dependency "rainbow"
  s.add_runtime_dependency "react_on_rails", ReactOnRails::VERSION
  s.add_development_dependency "bundler"
  s.add_development_dependency "commonmarker"
  s.add_development_dependency "gem-release"
  s.add_development_dependency "yard"
end
