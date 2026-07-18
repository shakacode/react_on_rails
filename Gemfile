# frozen_string_literal: true

source "https://rubygems.org"

# Root Gemfile for repo-wide lint, hook, release, and benchmark script spec tooling only.
# Package/runtime dependencies stay in the package Gemfiles so root bundle install
# remains small.
group :development, :test do
  gem "base64", "0.3.0", require: false
  gem "benchmark", "0.5.0", require: false
  gem "gem-release", "2.2.4", require: false
  gem "lefthook", "2.1.9", require: false
  gem "minitest", "6.0.6", require: false
  gem "rake", "13.4.2", require: false
  gem "rspec", "3.13.2", require: false
  gem "rubocop", "1.61.0", require: false
  gem "rubocop-performance", "1.20.2", require: false
  gem "rubocop-rspec", "2.31.0", require: false
end
