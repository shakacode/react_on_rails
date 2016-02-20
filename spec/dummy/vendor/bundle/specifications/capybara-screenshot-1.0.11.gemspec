# -*- encoding: utf-8 -*-
# stub: capybara-screenshot 1.0.11 ruby lib

Gem::Specification.new do |s|
  s.name = "capybara-screenshot"
  s.version = "1.0.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Matthew O'Riordan"]
  s.date = "2015-07-22"
  s.description = "When a Cucumber step fails, it is useful to create a screenshot image and HTML file of the current page"
  s.email = ["matthew.oriordan@gmail.com"]
  s.homepage = "http://github.com/mattheworiordan/capybara-screenshot"
  s.licenses = ["MIT"]
  s.rubyforge_project = "capybara-screenshot"
  s.rubygems_version = "2.5.1"
  s.summary = "Automatically create snapshots when Cucumber steps fail with Capybara and Rails"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capybara>, ["< 3", ">= 1.0"])
      s.add_runtime_dependency(%q<launchy>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<timecop>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<aruba>, [">= 0"])
      s.add_development_dependency(%q<sinatra>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<spinach>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<capybara>, ["< 3", ">= 1.0"])
      s.add_dependency(%q<launchy>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<timecop>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<aruba>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<spinach>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<capybara>, ["< 3", ">= 1.0"])
    s.add_dependency(%q<launchy>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<timecop>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<aruba>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<spinach>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
