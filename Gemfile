# frozen_string_literal: true

# Root Gemfile for developer convenience and RuboCop tooling.
# RuboCop is owned here so the monorepo uses one locked version.

# Use the open-source gem's Gemfile
eval_gemfile File.expand_path("react_on_rails/Gemfile", __dir__)

group :development, :test do
  gem "rubocop", "1.61.0", require: false
  gem "rubocop-performance", "~>1.20.0", require: false
  gem "rubocop-rspec", "~>2.26", require: false
end
