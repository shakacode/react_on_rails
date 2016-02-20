# -*- encoding: utf-8 -*-
# stub: sprockets-rails 3.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "sprockets-rails"
  s.version = "3.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Joshua Peek"]
  s.date = "2016-01-28"
  s.email = "josh@joshpeek.com"
  s.homepage = "https://github.com/rails/sprockets-rails"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "Sprockets Rails integration"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sprockets>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<actionpack>, [">= 4.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 4.0"])
      s.add_development_dependency(%q<railties>, [">= 4.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<sass>, [">= 0"])
      s.add_development_dependency(%q<uglifier>, [">= 0"])
    else
      s.add_dependency(%q<sprockets>, [">= 3.0.0"])
      s.add_dependency(%q<actionpack>, [">= 4.0"])
      s.add_dependency(%q<activesupport>, [">= 4.0"])
      s.add_dependency(%q<railties>, [">= 4.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<sass>, [">= 0"])
      s.add_dependency(%q<uglifier>, [">= 0"])
    end
  else
    s.add_dependency(%q<sprockets>, [">= 3.0.0"])
    s.add_dependency(%q<actionpack>, [">= 4.0"])
    s.add_dependency(%q<activesupport>, [">= 4.0"])
    s.add_dependency(%q<railties>, [">= 4.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<sass>, [">= 0"])
    s.add_dependency(%q<uglifier>, [">= 0"])
  end
end
