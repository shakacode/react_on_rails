# encoding: UTF-8

# Try to first load io-like from rubygems and then fall back to assuming a
# standard installation.
begin
  require 'rubygems'
  gem 'io-like', '>= 0.3.0'
rescue LoadError
  # Failed to load via rubygems.
end

# This will work for the gem and standard install assuming io-like is available
# at all.
require 'io/like'
