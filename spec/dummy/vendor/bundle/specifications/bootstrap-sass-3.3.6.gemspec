# -*- encoding: utf-8 -*-
# stub: bootstrap-sass 3.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "bootstrap-sass"
  s.version = "3.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Thomas McDonald"]
  s.date = "2015-11-24"
  s.email = "tom@conceptcoding.co.uk"
  s.homepage = "https://github.com/twbs/bootstrap-sass"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "bootstrap-sass is a Sass-powered version of Bootstrap 3, ready to drop right into your Sass powered applications."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sass>, [">= 3.3.4"])
      s.add_runtime_dependency(%q<autoprefixer-rails>, [">= 5.2.1"])
      s.add_development_dependency(%q<minitest>, ["~> 5.8"])
      s.add_development_dependency(%q<minitest-reporters>, ["~> 1.1"])
      s.add_development_dependency(%q<capybara>, [">= 2.5.0"])
      s.add_development_dependency(%q<poltergeist>, [">= 0"])
      s.add_development_dependency(%q<actionpack>, [">= 4.1.5"])
      s.add_development_dependency(%q<activesupport>, [">= 4.1.5"])
      s.add_development_dependency(%q<json>, [">= 1.8.1"])
      s.add_development_dependency(%q<sprockets-rails>, [">= 2.1.3"])
      s.add_development_dependency(%q<jquery-rails>, [">= 3.1.0"])
      s.add_development_dependency(%q<slim-rails>, [">= 0"])
      s.add_development_dependency(%q<uglifier>, [">= 0"])
      s.add_development_dependency(%q<term-ansicolor>, [">= 0"])
    else
      s.add_dependency(%q<sass>, [">= 3.3.4"])
      s.add_dependency(%q<autoprefixer-rails>, [">= 5.2.1"])
      s.add_dependency(%q<minitest>, ["~> 5.8"])
      s.add_dependency(%q<minitest-reporters>, ["~> 1.1"])
      s.add_dependency(%q<capybara>, [">= 2.5.0"])
      s.add_dependency(%q<poltergeist>, [">= 0"])
      s.add_dependency(%q<actionpack>, [">= 4.1.5"])
      s.add_dependency(%q<activesupport>, [">= 4.1.5"])
      s.add_dependency(%q<json>, [">= 1.8.1"])
      s.add_dependency(%q<sprockets-rails>, [">= 2.1.3"])
      s.add_dependency(%q<jquery-rails>, [">= 3.1.0"])
      s.add_dependency(%q<slim-rails>, [">= 0"])
      s.add_dependency(%q<uglifier>, [">= 0"])
      s.add_dependency(%q<term-ansicolor>, [">= 0"])
    end
  else
    s.add_dependency(%q<sass>, [">= 3.3.4"])
    s.add_dependency(%q<autoprefixer-rails>, [">= 5.2.1"])
    s.add_dependency(%q<minitest>, ["~> 5.8"])
    s.add_dependency(%q<minitest-reporters>, ["~> 1.1"])
    s.add_dependency(%q<capybara>, [">= 2.5.0"])
    s.add_dependency(%q<poltergeist>, [">= 0"])
    s.add_dependency(%q<actionpack>, [">= 4.1.5"])
    s.add_dependency(%q<activesupport>, [">= 4.1.5"])
    s.add_dependency(%q<json>, [">= 1.8.1"])
    s.add_dependency(%q<sprockets-rails>, [">= 2.1.3"])
    s.add_dependency(%q<jquery-rails>, [">= 3.1.0"])
    s.add_dependency(%q<slim-rails>, [">= 0"])
    s.add_dependency(%q<uglifier>, [">= 0"])
    s.add_dependency(%q<term-ansicolor>, [">= 0"])
  end
end
