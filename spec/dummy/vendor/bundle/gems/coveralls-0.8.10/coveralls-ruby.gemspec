lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coveralls/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Nick Merwin", "Wil Gieseler"]
  gem.email         = ["nick@lemurheavy.com", "supapuerco@gmail.com"]
  gem.description   = "A Ruby implementation of the Coveralls API."
  gem.summary       = "A Ruby implementation of the Coveralls API."
  gem.homepage      = "https://coveralls.io"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "coveralls"
  gem.require_paths = ["lib"]
  gem.version       = Coveralls::VERSION

  gem.required_ruby_version = '>= 1.8.7'

  gem.add_dependency 'json', '~> 1.8'
  gem.add_dependency 'rest-client', '>= 1.6.8', '< 2'
  gem.add_dependency 'simplecov', '~> 0.11.0'
  gem.add_dependency 'tins', '~> 1.6.0'
  gem.add_dependency 'term-ansicolor', '~> 1.3'
  gem.add_dependency 'thor', '~> 0.19.1'

  gem.add_development_dependency 'bundler', '~> 1.7'
end
