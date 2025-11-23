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

  repo_root = File.expand_path("..", __dir__)
  s.files = Dir.chdir(repo_root) do
    `git ls-files -z`.split("\x0").select do |f|
      f.start_with?("react_on_rails/")
    end.map { |f| f.sub(%r{^react_on_rails/}, "") }.reject do |f|
      f.match(%r{^(spec|tmp)/})
    end
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.0.0"

  s.add_dependency "addressable"
  s.add_dependency "connection_pool"
  s.add_dependency "execjs", "~> 2.5"
  s.add_dependency "rails", ">= 5.2"
  s.add_dependency "rainbow", "~> 3.0"
  s.add_dependency "shakapacker", ">= 6.0"

  s.add_development_dependency "gem-release"
  s.post_install_message = '
--------------------------------------------------------------------------------
Checkout https://www.shakacode.com/react-on-rails-pro for information about
"React on Rails Pro" which includes a gem for better performance, via caching helpers, and our
node rendering server, support for React 19, and much more.
--------------------------------------------------------------------------------
'
end
# rubocop:enable Metrics/BlockLength
