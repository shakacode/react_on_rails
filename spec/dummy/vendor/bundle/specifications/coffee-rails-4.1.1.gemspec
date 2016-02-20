# -*- encoding: utf-8 -*-
# stub: coffee-rails 4.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "coffee-rails"
  s.version = "4.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Santiago Pastorino"]
  s.date = "2015-12-18"
  s.description = "CoffeeScript adapter for the Rails asset pipeline."
  s.email = ["santiago@wyeworks.com"]
  s.homepage = "https://github.com/rails/coffee-rails"
  s.licenses = ["MIT"]
  s.rubyforge_project = "coffee-rails"
  s.rubygems_version = "2.5.1"
  s.summary = "CoffeeScript adapter for the Rails asset pipeline."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<coffee-script>, [">= 2.2.0"])
      s.add_runtime_dependency(%q<railties>, ["< 5.1.x", ">= 4.0.0"])
    else
      s.add_dependency(%q<coffee-script>, [">= 2.2.0"])
      s.add_dependency(%q<railties>, ["< 5.1.x", ">= 4.0.0"])
    end
  else
    s.add_dependency(%q<coffee-script>, [">= 2.2.0"])
    s.add_dependency(%q<railties>, ["< 5.1.x", ">= 4.0.0"])
  end
end
