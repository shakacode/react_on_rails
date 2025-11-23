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

  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(docs|test|spec|features|gen-examples|tmp|node_modules|packages|coverage|rakelib|script)/}) ||
      f.match(/^(jest\.config\.js|book\.json|package\.json|package-scripts\.yml|yarn\.lock|\..*)/) ||
      # Exclude Pro-only files from MIT gem
      f.match(/^react_on_rails_pro/) ||
      f.match(%r{^lib/react_on_rails_pro}) ||
      f.match(%r{^lib/tasks/(assets_pro|v8_log_processor)\.rake$})
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

  # rubocop:disable Gemspec/DevelopmentDependencies
  s.add_development_dependency "gem-release"
  # rubocop:enable Gemspec/DevelopmentDependencies
  s.post_install_message = '
--------------------------------------------------------------------------------
Checkout https://www.shakacode.com/react-on-rails-pro for information about
"React on Rails Pro" which includes a gem for better performance, via caching helpers, and our
node rendering server, support for React 19, and much more.
--------------------------------------------------------------------------------
'
  s.metadata["rubygems_mfa_required"] = "true"
end
# rubocop:enable Metrics/BlockLength
