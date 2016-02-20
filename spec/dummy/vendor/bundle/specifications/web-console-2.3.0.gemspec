# -*- encoding: utf-8 -*-
# stub: web-console 2.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "web-console"
  s.version = "2.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Charlie Somerville", "Genadi Samokovarov", "Guillermo Iguaran", "Ryan Dao"]
  s.date = "2016-01-27"
  s.email = ["charlie@charliesomerville.com", "gsamokovarov@gmail.com", "guilleiguaran@gmail.com", "daoduyducduong@gmail.com"]
  s.homepage = "https://github.com/rails/web-console"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "A debugging tool for your Ruby on Rails applications."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 4.0"])
      s.add_runtime_dependency(%q<activemodel>, [">= 4.0"])
      s.add_runtime_dependency(%q<sprockets-rails>, ["< 4.0", ">= 2.0"])
      s.add_runtime_dependency(%q<binding_of_caller>, [">= 0.7.2"])
      s.add_development_dependency(%q<actionmailer>, [">= 4.0"])
      s.add_development_dependency(%q<activerecord>, [">= 4.0"])
    else
      s.add_dependency(%q<railties>, [">= 4.0"])
      s.add_dependency(%q<activemodel>, [">= 4.0"])
      s.add_dependency(%q<sprockets-rails>, ["< 4.0", ">= 2.0"])
      s.add_dependency(%q<binding_of_caller>, [">= 0.7.2"])
      s.add_dependency(%q<actionmailer>, [">= 4.0"])
      s.add_dependency(%q<activerecord>, [">= 4.0"])
    end
  else
    s.add_dependency(%q<railties>, [">= 4.0"])
    s.add_dependency(%q<activemodel>, [">= 4.0"])
    s.add_dependency(%q<sprockets-rails>, ["< 4.0", ">= 2.0"])
    s.add_dependency(%q<binding_of_caller>, [">= 0.7.2"])
    s.add_dependency(%q<actionmailer>, [">= 4.0"])
    s.add_dependency(%q<activerecord>, [">= 4.0"])
  end
end
