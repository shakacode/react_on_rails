# -*- encoding: utf-8 -*-
# stub: chromedriver-helper 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "chromedriver-helper"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Mike Dalessio"]
  s.date = "2015-06-06"
  s.description = "Easy installation and use of chromedriver, the Chromium project's selenium webdriver adapter."
  s.email = ["mike.dalessio@gmail.com"]
  s.executables = ["chromedriver", "chromedriver-update"]
  s.files = ["bin/chromedriver", "bin/chromedriver-update"]
  s.homepage = "https://github.com/flavorjones/loofah"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Easy installation and use of chromedriver."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 3.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.6"])
      s.add_runtime_dependency(%q<archive-zip>, ["~> 0.7.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 3.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.6"])
      s.add_dependency(%q<archive-zip>, ["~> 0.7.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 3.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.6"])
    s.add_dependency(%q<archive-zip>, ["~> 0.7.0"])
  end
end
