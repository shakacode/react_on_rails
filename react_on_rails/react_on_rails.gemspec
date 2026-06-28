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
  s.homepage      = "https://reactonrails.com/docs/"
  s.license       = "MIT"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/shakacode/react_on_rails/issues",
    "changelog_uri" => "https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://reactonrails.com/docs/",
    "homepage_uri" => "https://reactonrails.com/docs/",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/shakacode/react_on_rails/tree/main/react_on_rails"
  }

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(spec|tmp|spike)/})
    end
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.3.0"

  s.add_dependency "addressable"
  s.add_dependency "connection_pool"
  s.add_dependency "execjs", "~> 2.5"
  s.add_dependency "rails", ">= 5.2"
  s.add_dependency "rainbow", "~> 3.0"
  # Minimum 6.5.6 for prepend_javascript_pack_tag, used by generated Tailwind layouts.
  # auto_load_bundle feature requires >= 7.0
  # (see PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING)
  s.add_dependency "shakapacker", ">= 6.5.6"

  s.add_development_dependency "gem-release"
  s.post_install_message = <<~MESSAGE
    --------------------------------------------------------------------------------
    Need React Server Components, streaming SSR, caching, or faster Node-based SSR?
    React on Rails Pro is free to try in development, CI/CD, and staging.
    Compare OSS vs Pro: https://reactonrails.com/docs/getting-started/oss-vs-pro/
    Pro quick start: https://reactonrails.com/docs/getting-started/pro-quick-start/
    Contact ShakaCode: https://www.shakacode.com/contact/
    --------------------------------------------------------------------------------
  MESSAGE
end
# rubocop:enable Metrics/BlockLength
