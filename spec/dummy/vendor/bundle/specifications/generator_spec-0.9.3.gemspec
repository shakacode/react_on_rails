# -*- encoding: utf-8 -*-
# stub: generator_spec 0.9.3 ruby lib

Gem::Specification.new do |s|
  s.name = "generator_spec"
  s.version = "0.9.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Steve Hodgkiss"]
  s.date = "2014-11-28"
  s.description = "Test Rails generators with RSpec"
  s.email = ["steve@hodgkiss.me.uk"]
  s.homepage = "https://github.com/stevehodgkiss/generator_spec"
  s.licenses = ["MIT"]
  s.rubyforge_project = "generator_spec"
  s.rubygems_version = "2.5.1"
  s.summary = "Test Rails generators with RSpec"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<railties>, [">= 3.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<railties>, [">= 3.0.0"])
      s.add_dependency(%q<rspec>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<railties>, [">= 3.0.0"])
    s.add_dependency(%q<rspec>, ["~> 3.0"])
  end
end
