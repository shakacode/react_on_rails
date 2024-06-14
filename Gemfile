# frozen_string_literal: true

source "https://rubygems.org"

# to use appraisal to update ci gemfiles, see https://github.com/thoughtbot/appraisal/issues/154
# following appraisal use, you will need to modify the created gemfiles to use relative paths instead of absolute paths
# gem "appraisal"

# Specify your gem"s dependencies in react_on_rails.gemspec
gemspec

eval_gemfile File.expand_path("./Gemfile.development_dependencies", __dir__)
