source "https://rubygems.org"

# Specify your gem"s dependencies in react_on_rails.gemspec
gemspec

# Comment out before final commit
gem "react_on_rails", path: "../react_on_rails"
gem "webpacker", "3.4.3"

# gem "react_on_rails", ">= 11.0.4"

# The following gems are dependencies of the gem's dummy/example apps, not the gem itself.
# They must be defined here because of the way Travis CI works, in that it will only
# bundle install from a single Gemfile. Therefore, all gems that we will need for any dummy/example
# app have to be manually added to this file.
gem "bootstrap-sass"
# gem "coffee-rails"
gem "jbuilder"
gem "jquery-rails"
gem "puma"
gem "rails", ">= 5.2"

gem "rails_12factor"
gem "rubocop", require: false
gem "ruby-lint", require: false
gem "sass-rails"
gem "scss_lint", require: false
gem "sdoc", group: :doc
gem "spring"
gem "sqlite3"
# gem "mini_racer"
# if ENV["ENABLE_TURBOLINKS_2"].nil? || ENV["ENABLE_TURBOLINKS_2"].strip.empty?
#   gem "turbolinks", "~> 5.0"
# else
#   gem "turbolinks", "2.5.3"
# end
gem "uglifier" # , ">= 2.7.2"
gem "web-console", group: :development

# below are copied from spec/dummy/Gemfile
gem "capybara"
gem "capybara-screenshot"
gem "rspec-rails"
gem "rspec-retry"
# Trouble installing on Sierra
# gem "capybara-webkit"
gem "chromedriver-helper"
gem "equivalent-xml", github: "mbklein/equivalent-xml"
gem "launchy"
gem "poltergeist"
gem "selenium-webdriver"
