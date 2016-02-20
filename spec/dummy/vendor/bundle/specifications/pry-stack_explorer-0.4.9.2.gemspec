# -*- encoding: utf-8 -*-
# stub: pry-stack_explorer 0.4.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-stack_explorer"
  s.version = "0.4.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2015-02-16"
  s.description = "Walk the stack in a Pry session"
  s.email = "jrmair@gmail.com"
  s.homepage = "https://github.com/pry/pry-stack_explorer"
  s.rubygems_version = "2.5.1"
  s.summary = "Walk the stack in a Pry session"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<binding_of_caller>, [">= 0.7"])
      s.add_runtime_dependency(%q<pry>, [">= 0.9.11"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
    else
      s.add_dependency(%q<binding_of_caller>, [">= 0.7"])
      s.add_dependency(%q<pry>, [">= 0.9.11"])
      s.add_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<binding_of_caller>, [">= 0.7"])
    s.add_dependency(%q<pry>, [">= 0.9.11"])
    s.add_dependency(%q<bacon>, ["~> 1.1.0"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
  end
end
