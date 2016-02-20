# -*- encoding: utf-8 -*-
# stub: arel 6.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "arel"
  s.version = "6.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Aaron Patterson", "Bryan Helmkamp", "Emilio Tagua", "Nick Kallen"]
  s.date = "2015-08-04"
  s.description = "Arel Really Exasperates Logicians\n\nArel is a SQL AST manager for Ruby. It\n\n1. Simplifies the generation of complex SQL queries\n2. Adapts to various RDBMSes\n\nIt is intended to be a framework framework; that is, you can build your own ORM\nwith it, focusing on innovative object and collection modeling as opposed to\ndatabase compatibility and query generation."
  s.email = ["aaron@tenderlovemaking.com", "bryan@brynary.com", "miloops@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "MIT-LICENSE.txt", "README.markdown"]
  s.files = ["History.txt", "MIT-LICENSE.txt", "README.markdown"]
  s.homepage = "https://github.com/rails/arel"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.markdown"]
  s.rubygems_version = "2.5.1"
  s.summary = "Arel Really Exasperates Logicians  Arel is a SQL AST manager for Ruby"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.4"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.4"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.4"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
  end
end
