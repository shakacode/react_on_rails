# -*- encoding: utf-8 -*-
# stub: pry-rails 0.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-rails"
  s.version = "0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Robin Wenglewski"]
  s.date = "2015-03-28"
  s.email = ["robin@wenglewski.de"]
  s.homepage = "https://github.com/rweng/pry-rails"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Use Pry as your rails console"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<pry>, [">= 0.9.10"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<pry>, [">= 0.9.10"])
      s.add_dependency(%q<appraisal>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<pry>, [">= 0.9.10"])
    s.add_dependency(%q<appraisal>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
