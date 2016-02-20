# -*- encoding: utf-8 -*-
# stub: awesome_print 1.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "awesome_print"
  s.version = "1.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Dvorkin"]
  s.date = "2014-12-31"
  s.description = "Great Ruby dubugging companion: pretty print Ruby objects to visualize their structure. Supports custom object formatting via plugins"
  s.email = "mike@dvorkin.net"
  s.homepage = "http://github.com/michaeldv/awesome_print"
  s.licenses = ["MIT"]
  s.rubyforge_project = "awesome_print"
  s.rubygems_version = "2.5.1"
  s.summary = "Pretty print Ruby objects with proper indentation and colors"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 3.0.0"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
      s.add_development_dependency(%q<fakefs>, [">= 0.2.1"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<nokogiri>, [">= 1.6.5"])
    else
      s.add_dependency(%q<rspec>, [">= 3.0.0"])
      s.add_dependency(%q<appraisal>, [">= 0"])
      s.add_dependency(%q<fakefs>, [">= 0.2.1"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 1.6.5"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 3.0.0"])
    s.add_dependency(%q<appraisal>, [">= 0"])
    s.add_dependency(%q<fakefs>, [">= 0.2.1"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 1.6.5"])
  end
end
