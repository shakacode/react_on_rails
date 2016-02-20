# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "blankslate"

Gem::Specification.new do |s|
  s.name        = "blankslate"
  s.version     = File.read('VERSION')
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'BlankSlate extracted from Builder.'
  s.email       = 'rubygems@6brand.com'
  s.authors     = ['Jim Weirich', 'David Masover', 'Jack Danger Canty']
  s.email       = "rubygems@6brand.com"
  s.homepage    = "http://github.com/masover/blankslate"

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'bundler'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
