# -*- encoding: utf-8 -*-
# stub: launchy 2.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "launchy"
  s.version = "2.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jeremy Hinegardner"]
  s.date = "2014-11-03"
  s.description = "Launchy is helper class for launching cross-platform applications in a fire and forget manner. There are application concepts (browser, email client, etc) that are common across all platforms, and they may be launched differently on each platform. Launchy is here to make a common approach to launching external application from within ruby programs."
  s.email = "jeremy@copiousfreetime.org"
  s.executables = ["launchy"]
  s.extra_rdoc_files = ["CONTRIBUTING.md", "HISTORY.md", "Manifest.txt", "README.md"]
  s.files = ["CONTRIBUTING.md", "HISTORY.md", "Manifest.txt", "README.md", "bin/launchy"]
  s.homepage = "http://github.com/copiousfreetime/launchy"
  s.licenses = ["ISC"]
  s.rdoc_options = ["--main", "README.md", "--markup", "tomdoc"]
  s.rubygems_version = "2.5.1"
  s.summary = "Launchy is helper class for launching cross-platform applications in a fire and forget manner."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.3"])
      s.add_development_dependency(%q<rake>, ["~> 10.1"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.1"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.3"])
      s.add_dependency(%q<rake>, ["~> 10.1"])
      s.add_dependency(%q<minitest>, ["~> 5.0"])
      s.add_dependency(%q<rdoc>, ["~> 4.1"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.3"])
    s.add_dependency(%q<rake>, ["~> 10.1"])
    s.add_dependency(%q<minitest>, ["~> 5.0"])
    s.add_dependency(%q<rdoc>, ["~> 4.1"])
  end
end
