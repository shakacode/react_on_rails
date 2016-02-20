# -*- encoding: utf-8 -*-
# stub: pry-rescue 1.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-rescue"
  s.version = "1.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Conrad Irwin", "banisterfiend", "epitron"]
  s.date = "2015-05-06"
  s.description = "Allows you to wrap code in Pry::rescue{ } to open a pry session at any unhandled exceptions"
  s.email = ["conrad.irwin@gmail.com", "jrmair@gmail.com", "chris@ill-logic.com"]
  s.executables = ["kill-pry-rescue", "rescue"]
  s.files = ["bin/kill-pry-rescue", "bin/rescue"]
  s.homepage = "https://github.com/ConradIrwin/pry-rescue"
  s.rubygems_version = "2.5.1"
  s.summary = "Open a pry session on any unhandled exceptions"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<pry>, [">= 0"])
      s.add_runtime_dependency(%q<interception>, [">= 0.5"])
      s.add_development_dependency(%q<pry-stack_explorer>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<redcarpet>, [">= 0"])
      s.add_development_dependency(%q<capybara>, [">= 0"])
    else
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<interception>, [">= 0.5"])
      s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<redcarpet>, [">= 0"])
      s.add_dependency(%q<capybara>, [">= 0"])
    end
  else
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<interception>, [">= 0.5"])
    s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<redcarpet>, [">= 0"])
    s.add_dependency(%q<capybara>, [">= 0"])
  end
end
