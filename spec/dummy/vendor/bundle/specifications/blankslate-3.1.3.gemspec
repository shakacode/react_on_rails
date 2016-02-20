# -*- encoding: utf-8 -*-
# stub: blankslate 3.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "blankslate"
  s.version = "3.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jim Weirich", "David Masover", "Jack Danger Canty"]
  s.date = "2014-06-18"
  s.email = "rubygems@6brand.com"
  s.homepage = "http://github.com/masover/blankslate"
  s.rubygems_version = "2.5.1"
  s.summary = "BlankSlate extracted from Builder."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
  end
end
