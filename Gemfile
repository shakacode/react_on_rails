source "https://rubygems.org"

# Specify your gem"s dependencies in react_on_rails.gemspec
gemspec

# The following gems are dependencies of the gem's dummy/example apps, not the gem itself.
# They must be defined here because of the way Travis CI works, in that it will only
# bundle install from a single Gemfile. Therefore, all gems that we will need for any dummy/example
# app have to be manually added to this file.
gem "bootstrap-sass"
gem "jbuilder", "~> 2.0"
gem "jquery-rails"
gem "mini_racer"
gem "puma"
gem "rails", "5.1.1"
gem "rails_12factor"
gem "rubocop", "0.47.1", require: false
gem "ruby-lint", require: false
gem "sass-rails", "~> 5.0"
gem "scss_lint", require: false
gem "sdoc", "~> 0.4.0", group: :doc
gem "spring"
gem "sqlite3"
if ENV["ENABLE_TURBOLINKS_2"].nil? || ENV["ENABLE_TURBOLINKS_2"].strip.empty?
  gem "turbolinks", "~> 5.0"
else
  gem "turbolinks", "2.5.3"
end
gem "uglifier", ">= 2.7.2"
gem "web-console", "~> 2.0", group: :development

# below are copied from spec/dummy/Gemfile
gem "capybara"
gem "capybara-screenshot"
gem "rspec-rails"
gem "rspec-retry"
# Trouble installing on Sierra
# gem "capybara-webkit"
gem "chromedriver-helper"
gem "launchy"
gem "poltergeist"
gem "selenium-webdriver"
gem "webpacker_lite"

################################################################################
# Favorite debugging gems
gem "pry"
gem "pry-byebug"
gem "pry-doc"
gem "pry-rails"
gem "pry-rescue"
gem "pry-stack_explorer"
################################################################################
