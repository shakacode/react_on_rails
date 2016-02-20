source "https://rubygems.org"

# Uncomment this to use local copy of simplecov-html in development when checked out
# gem 'simplecov-html', :path => ::File.dirname(__FILE__) + '/../simplecov-html'

# Uncomment this to use development version of html formatter from github
# gem 'simplecov-html', :github => 'colszowka/simplecov-html'

gem "rake", ">= 10.3"

group :test do
  gem "rspec", ">= 3.2"
  # Older versions of some gems required for Ruby 1.8.7 support
  platform :ruby_18 do
    gem "activesupport", "~> 3.2.21"
    gem "i18n", "~> 0.6.11"
  end
  platform :jruby, :ruby_19, :ruby_20, :ruby_21, :ruby_22 do
    gem "aruba", "~> 0.7.4"
    gem "capybara", "~> 2.4"

    # Hack until Capybara fixes its gemspec. 3.0 removed 1.9 support.
    # See https://github.com/jnicklas/capybara/issues/1615
    gem "mime-types", "~> 2.0.0"

    gem "cucumber", "~> 2.0"
    gem "phantomjs", "~> 1.9"
    gem "poltergeist", "~> 1.1"
    gem "rubocop", ">= 0.30"
    gem "test-unit", "~> 3.0"
  end
end

gemspec
