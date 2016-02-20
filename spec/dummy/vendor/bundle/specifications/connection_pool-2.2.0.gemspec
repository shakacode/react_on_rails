# -*- encoding: utf-8 -*-
# stub: connection_pool 2.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "connection_pool"
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Mike Perham", "Damian Janowski"]
  s.date = "2015-04-11"
  s.description = "Generic connection pool for Ruby"
  s.email = ["mperham@gmail.com", "damian@educabilia.com"]
  s.homepage = "https://github.com/mperham/connection_pool"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Generic connection pool for Ruby"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 5.0.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 5.0.0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 5.0.0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
