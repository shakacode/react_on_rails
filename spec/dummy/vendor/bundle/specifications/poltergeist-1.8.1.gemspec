# -*- encoding: utf-8 -*-
# stub: poltergeist 1.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "poltergeist"
  s.version = "1.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jon Leighton"]
  s.date = "2015-11-24"
  s.description = "Poltergeist is a driver for Capybara that allows you to run your tests on a headless WebKit browser, provided by PhantomJS."
  s.email = ["j@jonathanleighton.com"]
  s.homepage = "https://github.com/teampoltergeist/poltergeist"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "PhantomJS driver for Capybara"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capybara>, ["~> 2.1"])
      s.add_runtime_dependency(%q<websocket-driver>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_runtime_dependency(%q<cliver>, ["~> 0.3.1"])
      s.add_development_dependency(%q<launchy>, ["~> 2.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.4.0"])
      s.add_development_dependency(%q<rspec-core>, ["!= 3.4.0"])
      s.add_development_dependency(%q<sinatra>, ["~> 1.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<image_size>, ["~> 1.0"])
      s.add_development_dependency(%q<pdf-reader>, ["~> 1.3.3"])
      s.add_development_dependency(%q<coffee-script>, ["~> 2.2"])
      s.add_development_dependency(%q<guard-coffeescript>, ["~> 2.0.0"])
    else
      s.add_dependency(%q<capybara>, ["~> 2.1"])
      s.add_dependency(%q<websocket-driver>, [">= 0.2.0"])
      s.add_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_dependency(%q<cliver>, ["~> 0.3.1"])
      s.add_dependency(%q<launchy>, ["~> 2.0"])
      s.add_dependency(%q<rspec>, ["~> 3.4.0"])
      s.add_dependency(%q<rspec-core>, ["!= 3.4.0"])
      s.add_dependency(%q<sinatra>, ["~> 1.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<image_size>, ["~> 1.0"])
      s.add_dependency(%q<pdf-reader>, ["~> 1.3.3"])
      s.add_dependency(%q<coffee-script>, ["~> 2.2"])
      s.add_dependency(%q<guard-coffeescript>, ["~> 2.0.0"])
    end
  else
    s.add_dependency(%q<capybara>, ["~> 2.1"])
    s.add_dependency(%q<websocket-driver>, [">= 0.2.0"])
    s.add_dependency(%q<multi_json>, ["~> 1.0"])
    s.add_dependency(%q<cliver>, ["~> 0.3.1"])
    s.add_dependency(%q<launchy>, ["~> 2.0"])
    s.add_dependency(%q<rspec>, ["~> 3.4.0"])
    s.add_dependency(%q<rspec-core>, ["!= 3.4.0"])
    s.add_dependency(%q<sinatra>, ["~> 1.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<image_size>, ["~> 1.0"])
    s.add_dependency(%q<pdf-reader>, ["~> 1.3.3"])
    s.add_dependency(%q<coffee-script>, ["~> 2.2"])
    s.add_dependency(%q<guard-coffeescript>, ["~> 2.0.0"])
  end
end
