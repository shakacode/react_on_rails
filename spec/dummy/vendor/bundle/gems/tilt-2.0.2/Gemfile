source 'https://rubygems.org'

gem 'rake'
gem 'minitest', '~> 5.0'

group :development do
  gem 'yard', '~> 0.8.6'
  gem 'ronn', '~> 0.7.3'
end

can_execjs = (RUBY_VERSION >= '1.9.3')

group :primary do
  gem 'builder'
  gem 'haml', '>= 2.2.11', '< 4'
  gem 'erubis'
  gem 'markaby'
  gem 'sass'

  if can_execjs
    gem 'less'
    gem 'coffee-script'
    gem 'babel-transpiler'
  end
end

platform :mri do
  gem 'duktape', '~> 1.2.1.0' if can_execjs
end

group :secondary do
  gem 'creole'
  gem 'kramdown'
  gem 'rdoc'
  gem 'radius'
  gem 'asciidoctor', '>= 0.1.0'
  gem 'liquid'
  gem 'maruku'

  if RUBY_VERSION > '1.9.3'
    gem 'prawn', '>= 2.0.0'
    gem 'pdf-reader', '~> 1.3.3'
  end

  gem 'nokogiri' if RUBY_VERSION > '1.9.2'

  platform :ruby do
    gem 'wikicloth'
    gem 'yajl-ruby'
    gem 'redcarpet' if RUBY_VERSION > '1.8.7'
    gem 'rdiscount', '>= 2.1.6' if RUBY_VERSION != '1.9.2'
    gem 'RedCloth'
  end

  platform :mri do
    gem 'bluecloth'
  end
end

## WHY do I have to do this?!?
platform :rbx do
  gem 'rubysl'
end

