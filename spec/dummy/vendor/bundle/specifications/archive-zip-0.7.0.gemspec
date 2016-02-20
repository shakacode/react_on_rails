# -*- encoding: utf-8 -*-
# stub: archive-zip 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "archive-zip"
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jeremy Bopp"]
  s.date = "2014-08-19"
  s.description = "Archive::Zip provides a simple Ruby-esque interface to creating, extracting, and\nupdating ZIP archives.  This implementation is 100% Ruby and loosely modeled on\nthe archive creation and extraction capabilities of InfoZip's zip and unzip\ntools.\n"
  s.email = ["jeremy@bopp.net"]
  s.homepage = "http://github.com/javanthropus/archive-zip"
  s.licenses = ["MIT"]
  s.rubyforge_project = "archive-zip"
  s.rubygems_version = "2.5.1"
  s.summary = "Simple, extensible, pure Ruby ZIP archive support."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<io-like>, ["~> 0.3.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.3"])
      s.add_development_dependency(%q<minitest>, ["~> 5.4"])
      s.add_development_dependency(%q<yard>, ["~> 0.8"])
      s.add_development_dependency(%q<yard-redcarpet-ext>, ["~> 0.0"])
      s.add_development_dependency(%q<github-markup>, ["~> 1.2"])
      s.add_development_dependency(%q<redcarpet>, ["~> 3.1"])
    else
      s.add_dependency(%q<io-like>, ["~> 0.3.0"])
      s.add_dependency(%q<rake>, ["~> 10.3"])
      s.add_dependency(%q<minitest>, ["~> 5.4"])
      s.add_dependency(%q<yard>, ["~> 0.8"])
      s.add_dependency(%q<yard-redcarpet-ext>, ["~> 0.0"])
      s.add_dependency(%q<github-markup>, ["~> 1.2"])
      s.add_dependency(%q<redcarpet>, ["~> 3.1"])
    end
  else
    s.add_dependency(%q<io-like>, ["~> 0.3.0"])
    s.add_dependency(%q<rake>, ["~> 10.3"])
    s.add_dependency(%q<minitest>, ["~> 5.4"])
    s.add_dependency(%q<yard>, ["~> 0.8"])
    s.add_dependency(%q<yard-redcarpet-ext>, ["~> 0.0"])
    s.add_dependency(%q<github-markup>, ["~> 1.2"])
    s.add_dependency(%q<redcarpet>, ["~> 3.1"])
  end
end
