# -*- encoding: utf-8 -*-
# stub: capybara-webkit 1.8.0 ruby lib
# stub: extconf.rb

Gem::Specification.new do |s|
  s.name = "capybara-webkit"
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["thoughtbot", "Joe Ferris", "Matt Horan", "Matt Mongeau", "Mike Burns", "Jason Morrison"]
  s.date = "2016-01-22"
  s.email = "support@thoughtbot.com"
  s.extensions = ["extconf.rb"]
  s.files = ["extconf.rb"]
  s.homepage = "http://github.com/thoughtbot/capybara-webkit"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Headless Webkit driver for Capybara"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capybara>, ["< 2.7.0", ">= 2.3.0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14.0"])
      s.add_development_dependency(%q<sinatra>, [">= 0"])
      s.add_development_dependency(%q<mini_magick>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<appraisal>, ["~> 0.4.0"])
      s.add_development_dependency(%q<selenium-webdriver>, [">= 0"])
      s.add_development_dependency(%q<launchy>, [">= 0"])
    else
      s.add_dependency(%q<capybara>, ["< 2.7.0", ">= 2.3.0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.14.0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<mini_magick>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<appraisal>, ["~> 0.4.0"])
      s.add_dependency(%q<selenium-webdriver>, [">= 0"])
      s.add_dependency(%q<launchy>, [">= 0"])
    end
  else
    s.add_dependency(%q<capybara>, ["< 2.7.0", ">= 2.3.0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.14.0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<mini_magick>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<appraisal>, ["~> 0.4.0"])
    s.add_dependency(%q<selenium-webdriver>, [">= 0"])
    s.add_dependency(%q<launchy>, [">= 0"])
  end
end
