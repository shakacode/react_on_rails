# -*- encoding: utf-8 -*-
# stub: jquery-rails 4.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jquery-rails"
  s.version = "4.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Andr\u{e9} Arko"]
  s.date = "2016-01-12"
  s.description = "This gem provides jQuery and the jQuery-ujs driver for your Rails 4+ application."
  s.email = ["andre@arko.net"]
  s.homepage = "http://rubygems.org/gems/jquery-rails"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "Use jQuery with Rails 4+"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 4.2.0"])
      s.add_runtime_dependency(%q<thor>, ["< 2.0", ">= 0.14"])
      s.add_runtime_dependency(%q<rails-dom-testing>, ["~> 1.0"])
    else
      s.add_dependency(%q<railties>, [">= 4.2.0"])
      s.add_dependency(%q<thor>, ["< 2.0", ">= 0.14"])
      s.add_dependency(%q<rails-dom-testing>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<railties>, [">= 4.2.0"])
    s.add_dependency(%q<thor>, ["< 2.0", ">= 0.14"])
    s.add_dependency(%q<rails-dom-testing>, ["~> 1.0"])
  end
end
