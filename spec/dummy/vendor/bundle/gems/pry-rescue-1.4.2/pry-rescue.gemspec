Gem::Specification.new do |s|
  s.name          = 'pry-rescue'
  s.version       = '1.4.2'
  s.summary       = 'Open a pry session on any unhandled exceptions'
  s.description   = 'Allows you to wrap code in Pry::rescue{ } to open a pry session at any unhandled exceptions'
  s.homepage      = 'https://github.com/ConradIrwin/pry-rescue'
  s.email         = ['conrad.irwin@gmail.com', 'jrmair@gmail.com', 'chris@ill-logic.com']
  s.authors       = ['Conrad Irwin', 'banisterfiend', 'epitron']
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']
  s.executables   = s.files.grep(%r{^bin/}).map{|f| File.basename f}

  s.add_dependency 'pry'
  s.add_dependency 'interception', '>= 0.5'

  s.add_development_dependency 'pry-stack_explorer' # upgrade to regular dep?

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'capybara'
end
