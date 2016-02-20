begin
  gem 'rdoc', '~> 4.0.0'
  require File.join(File.dirname(__FILE__), '/../sdoc')
rescue Gem::LoadError
end
