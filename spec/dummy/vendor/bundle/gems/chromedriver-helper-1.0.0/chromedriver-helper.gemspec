# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chromedriver/helper/version"

Gem::Specification.new do |s|
  s.name        = "chromedriver-helper"
  s.version     = Chromedriver::Helper::VERSION
  s.authors     = ["Mike Dalessio"]
  s.email       = ["mike.dalessio@gmail.com"]
  s.homepage    = "https://github.com/flavorjones/loofah"
  s.summary     = "Easy installation and use of chromedriver."
  s.description = "Easy installation and use of chromedriver, the Chromium project's selenium webdriver adapter."
  s.licenses    = ["MIT"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec",   "~> 3.0"
  s.add_development_dependency "rake",    "~> 10.0"

  s.add_runtime_dependency "nokogiri",    "~> 1.6"
  s.add_runtime_dependency "archive-zip", "~> 0.7.0"
end
