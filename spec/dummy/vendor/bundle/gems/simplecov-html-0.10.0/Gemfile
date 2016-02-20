source "https://rubygems.org"

gemspec

gem "rake"

# Use local copy of simplecov in development when checked out, fetch from git otherwise
if File.directory?(File.dirname(__FILE__) + "/../simplecov")
  gem "simplecov", :path => File.dirname(__FILE__) + "/../simplecov"
else
  gem "simplecov", :git => "https://github.com/colszowka/simplecov"
end

group :test do
  gem "test-unit"
end

group :development do
  gem "rubocop"
  gem "sass"
  gem "sprockets"
end
