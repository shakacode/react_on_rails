# -*- encoding: utf-8 -*-
# stub: interception 0.5 ruby lib
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "interception"
  s.version = "0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Conrad Irwin"]
  s.date = "2014-03-06"
  s.description = "Provides a cross-platform ability to intercept all exceptions as they are raised."
  s.email = "conrad.irwin@gmail.com"
  s.extensions = ["ext/extconf.rb"]
  s.files = ["ext/extconf.rb"]
  s.homepage = "http://github.com/ConradIrwin/interception"
  s.rubygems_version = "2.5.1"
  s.summary = "Intercept exceptions as they are being raised"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
