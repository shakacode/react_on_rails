# -*- encoding: utf-8 -*-
# stub: slop 3.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "slop"
  s.version = "3.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Lee Jarvis"]
  s.date = "2014-07-18"
  s.description = "A simple DSL for gathering options and parsing the command line"
  s.email = "ljjarvis@gmail.com"
  s.homepage = "http://github.com/leejarvis/slop"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = "2.5.1"
  s.summary = "Simple Lightweight Option Parsing"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0.0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 5.0.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 5.0.0"])
  end
end
