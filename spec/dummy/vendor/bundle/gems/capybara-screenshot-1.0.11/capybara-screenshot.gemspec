# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capybara-screenshot/version"

Gem::Specification.new do |s|
  s.name        = "capybara-screenshot"
  s.version     = Capybara::Screenshot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew O'Riordan"]
  s.email       = ["matthew.oriordan@gmail.com"]
  s.homepage    = "http://github.com/mattheworiordan/capybara-screenshot"
  s.summary     = %q{Automatically create snapshots when Cucumber steps fail with Capybara and Rails}
  s.description = %q{When a Cucumber step fails, it is useful to create a screenshot image and HTML file of the current page}
  s.license     = 'MIT'

  s.rubyforge_project = "capybara-screenshot"

  if RUBY_VERSION < "1.9"
    s.add_dependency 'capybara', ['>= 1.0', '< 2']
  else
    s.add_dependency 'capybara', ['>= 1.0', '< 3']
  end
  s.add_dependency 'launchy'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'sinatra'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'spinach'
  s.add_development_dependency 'minitest'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
