# -*- encoding: utf-8 -*-
# stub: pry-doc 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-doc"
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2015-06-14"
  s.description = "Pry Doc is a Pry REPL plugin. It provides extended documentation support for the\nREPL by means of improving the `show-doc` and `show-source` commands. With help\nof the plugin the commands are be able to display the source code and the docs\nof Ruby methods and classes implemented in C.\ndocumentation\n"
  s.email = ["jrmair@gmail.com"]
  s.homepage = "https://github.com/pry/pry-doc"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Provides YARD and extended documentation support for Pry"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yard>, ["~> 0.8"])
      s.add_runtime_dependency(%q<pry>, ["~> 0.9"])
      s.add_development_dependency(%q<latest_ruby>, ["~> 0.0"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1"])
    else
      s.add_dependency(%q<yard>, ["~> 0.8"])
      s.add_dependency(%q<pry>, ["~> 0.9"])
      s.add_dependency(%q<latest_ruby>, ["~> 0.0"])
      s.add_dependency(%q<bacon>, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<yard>, ["~> 0.8"])
    s.add_dependency(%q<pry>, ["~> 0.9"])
    s.add_dependency(%q<latest_ruby>, ["~> 0.0"])
    s.add_dependency(%q<bacon>, ["~> 1.1"])
  end
end
