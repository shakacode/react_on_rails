# frozen_string_literal: true

# Root Gemfile for repo-wide lint/tooling.
#
# This is intentionally a lint/tooling-only bundle: RuboCop is owned here so the
# monorepo (OSS and Pro) resolves it from one committed root Gemfile.lock.
# It deliberately does NOT eval_gemfile the react_on_rails package Gemfile,
# so a root `bundle install` for lint-only workflows stays fast and does not
# pull in the Rails/test/runtime stack. The package Gemfiles continue to own
# their RBS/test/runtime dependencies.
#
# rspec is included only to run the plain-Ruby benchmarks/ script specs from the
# repo root (benchmark.yml). Those specs deliberately load no Rails and no
# react_on_rails gem (see benchmarks/spec/spec_helper.rb), so the bare rspec gem
# is all the root bundle needs — not the package's rspec-rails stack.
#
# The pinned versions below must match what the react_on_rails and
# react_on_rails_pro package locks resolve, to avoid version drift and
# unexpected new offenses.

source "https://rubygems.org"

gem "rubocop", "1.61.0", require: false
gem "rubocop-performance", "1.20.2", require: false
gem "rubocop-rspec", "2.31.0", require: false

gem "rspec", "~> 3.13", require: false
