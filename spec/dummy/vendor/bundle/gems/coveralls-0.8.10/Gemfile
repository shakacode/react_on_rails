source 'https://rubygems.org'

# Specify your gem's dependencies in coveralls-ruby.gemspec
gemspec

gem 'rake', '>= 10.4'
gem 'rspec', '>= 3.2'
gem 'simplecov', :require => false
gem 'truthy', '>= 1'
gem 'vcr', '>= 2.9'
gem 'webmock', '>= 1.20'

platforms :ruby_18 do
  gem 'mime-types', '~> 1.25'
  gem 'rest-client', '~> 1.6.0'
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.9.5'
end

platform :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
  gem 'rubinius-developer_tools'
end

group :test do
  gem 'pry'
end
