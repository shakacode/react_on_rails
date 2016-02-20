# -*- encoding: utf-8 -*-
# stub: actionmailer 4.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "actionmailer"
  s.version = "4.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Heinemeier Hansson"]
  s.date = "2015-06-25"
  s.description = "Email on Rails. Compose, deliver, receive, and test emails using the familiar controller/view pattern. First-class support for multipart email and attachments."
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.requirements = ["none"]
  s.rubygems_version = "2.5.1"
  s.summary = "Email composition, delivery, and receiving framework (part of Rails)."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, ["= 4.2.3"])
      s.add_runtime_dependency(%q<actionview>, ["= 4.2.3"])
      s.add_runtime_dependency(%q<activejob>, ["= 4.2.3"])
      s.add_runtime_dependency(%q<mail>, [">= 2.5.4", "~> 2.5"])
      s.add_runtime_dependency(%q<rails-dom-testing>, [">= 1.0.5", "~> 1.0"])
    else
      s.add_dependency(%q<actionpack>, ["= 4.2.3"])
      s.add_dependency(%q<actionview>, ["= 4.2.3"])
      s.add_dependency(%q<activejob>, ["= 4.2.3"])
      s.add_dependency(%q<mail>, [">= 2.5.4", "~> 2.5"])
      s.add_dependency(%q<rails-dom-testing>, [">= 1.0.5", "~> 1.0"])
    end
  else
    s.add_dependency(%q<actionpack>, ["= 4.2.3"])
    s.add_dependency(%q<actionview>, ["= 4.2.3"])
    s.add_dependency(%q<activejob>, ["= 4.2.3"])
    s.add_dependency(%q<mail>, [">= 2.5.4", "~> 2.5"])
    s.add_dependency(%q<rails-dom-testing>, [">= 1.0.5", "~> 1.0"])
  end
end
