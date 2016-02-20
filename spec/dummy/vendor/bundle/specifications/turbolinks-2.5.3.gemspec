# -*- encoding: utf-8 -*-
# stub: turbolinks 2.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "turbolinks"
  s.version = "2.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Heinemeier Hansson"]
  s.date = "2014-12-08"
  s.email = "david@loudthinking.com"
  s.homepage = "https://github.com/rails/turbolinks/"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Turbolinks makes following links in your web application faster (use with Rails Asset Pipeline)"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<coffee-rails>, [">= 0"])
    else
      s.add_dependency(%q<coffee-rails>, [">= 0"])
    end
  else
    s.add_dependency(%q<coffee-rails>, [">= 0"])
  end
end
